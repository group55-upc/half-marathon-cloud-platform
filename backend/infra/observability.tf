###############################################################################
# ESCALADO AUTOMATICO Y OBSERVABILIDAD
#
# Este archivo agrupa dos incorporaciones independientes del main.tf:
#
#   1. Escalado automatico del servicio ECS en funcion de la CPU
#   2. Alarmas de CloudWatch con notificacion por correo mediante SNS
#
# Ambos bloques se pueden desactivar con sus variables correspondientes, igual
# que se hace con enable-ECS, por si el laboratorio deniega algun permiso.
###############################################################################


## VARIABLES ##

variable "enable-autoscaling" {
  description = "Crear la politica de escalado automatico del servicio ECS"
  type        = bool
  default     = true
}

variable "enable-alarms" {
  description = "Crear el tema de SNS y las alarmas de CloudWatch"
  type        = bool
  default     = true
}

variable "ecs-autoscaling-min" {
  description = "Numero minimo de tareas del servicio"
  type        = number
  default     = 2
}

variable "ecs-autoscaling-max" {
  description = "Numero maximo de tareas del servicio"
  type        = number
  default     = 4
}

variable "ecs-autoscaling-cpu-target" {
  description = "Porcentaje de CPU objetivo. Por encima escala, por debajo reduce"
  type        = number
  default     = 70
}

variable "alert-emails" {
  description = "Correos que recibiran las alarmas. Lista vacia = sin suscripciones"
  type        = list(string)
  default     = []

  # No poner correos reales aqui: este archivo esta versionado.
  # Definirlos en terraform.tfvars, que esta en el .gitignore.
  # Ver terraform.tfvars.example
}





## ESCALADO AUTOMATICO DEL SERVICIO ECS ##
#
# Application Auto Scaling funciona en dos piezas:
#
#   1. El "scalable target" declara QUE se puede escalar y entre que limites.
#   2. La "policy" declara CUANDO hacerlo.
#
# Se usa target tracking, que es el modo mas sencillo y el recomendado: se
# indica un valor objetivo de CPU y AWS crea y gestiona por su cuenta las
# alarmas necesarias para mantenerlo. No hay que definir umbrales de subida y
# bajada por separado.

resource "aws_appautoscaling_target" "ecs-service" {
  count              = (var.enable-ECS && var.enable-autoscaling) ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs-cluster-name}/${var.ecs-service-name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.ecs-autoscaling-min
  max_capacity       = var.ecs-autoscaling-max

  # El servicio debe existir antes de poder registrarlo como escalable
  depends_on = [aws_ecs_service.ecs-service-one]
}

resource "aws_appautoscaling_policy" "ecs-cpu" {
  count              = (var.enable-ECS && var.enable-autoscaling) ? 1 : 0
  name               = "cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs-service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-service[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = var.ecs-autoscaling-cpu-target

    # Escalar hacia arriba rapido (1 min) y hacia abajo despacio (5 min).
    # Asimetrico a proposito: quedarse corto de capacidad degrada el servicio,
    # mientras que tener una tarea de mas un rato solo cuesta centimos.
    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}





## SNS: TEMA DE ALERTAS ##

resource "aws_sns_topic" "alertas" {
  count = var.enable-alarms ? 1 : 0
  name  = "marathon-alertas"
  tags  = local.tags
}

# Una suscripcion por cada correo de la lista.
#
# Se usa for_each y no count porque las suscripciones se identifican por la
# direccion, no por su posicion: si alguien se da de baja y se elimina del
# medio de la lista, con count Terraform recrearia todas las posteriores.
#
# OJO: cada suscripcion requiere confirmacion. AWS envia un correo con un
# enlace "Confirm subscription" que cada destinatario debe pulsar. Hasta
# entonces esa persona no recibe ninguna alarma.
resource "aws_sns_topic_subscription" "alertas-correo" {
  for_each  = var.enable-alarms ? toset(var.alert-emails) : toset([])
  topic_arn = aws_sns_topic.alertas[0].arn
  protocol  = "email"
  endpoint  = each.value
}





## ALARMAS DE CLOUDWATCH ##
#
# Cuatro alarmas, dentro de las diez gratuitas por cuenta.
#
# Nota sobre "treat_missing_data": cuando no hay trafico, algunas metricas no
# publican dato alguno. Se marca como "notBreaching" para que el silencio no
# se interprete como fallo, que es un error frecuente al configurar alarmas.

# 1. El backend devuelve errores del servidor
resource "aws_cloudwatch_metric_alarm" "backend-5xx" {
  count               = var.enable-alarms ? 1 : 0
  alarm_name          = "marathon-backend-errores-5xx"
  alarm_description   = "El backend ha devuelto 5 o mas errores 5xx en 5 minutos"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_alb.alb-backend.arn_suffix
    TargetGroup  = aws_alb_target_group.alb-tg-backend.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alertas[0].arn]
  ok_actions    = [aws_sns_topic.alertas[0].arn]
  tags          = local.tags
}

# 2. Alguna tarea ha dejado de pasar el health check
resource "aws_cloudwatch_metric_alarm" "tareas-no-sanas" {
  count               = var.enable-alarms ? 1 : 0
  alarm_name          = "marathon-tareas-no-sanas"
  alarm_description   = "Al menos una tarea no responde al health check del balanceador"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_alb.alb-backend.arn_suffix
    TargetGroup  = aws_alb_target_group.alb-tg-backend.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alertas[0].arn]
  ok_actions    = [aws_sns_topic.alertas[0].arn]
  tags          = local.tags
}

# 3. CPU sostenida alta. Con el escalado activo esto no deberia dispararse:
#    si lo hace, significa que se ha alcanzado el maximo de tareas.
resource "aws_cloudwatch_metric_alarm" "cpu-alta" {
  count               = (var.enable-ECS && var.enable-alarms) ? 1 : 0
  alarm_name          = "marathon-cpu-alta"
  alarm_description   = "CPU del servicio por encima del 85% durante 10 minutos. Posible techo de escalado"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs-cluster-name
    ServiceName = var.ecs-service-name
  }

  alarm_actions = [aws_sns_topic.alertas[0].arn]
  tags          = local.tags

  depends_on = [aws_ecs_service.ecs-service-one]
}

# 4. Memoria sostenida alta. A diferencia de la CPU, el escalado automatico
#    configurado no reacciona a la memoria, asi que esta alarma si requiere
#    intervencion manual (subir la memoria de la task definition).
resource "aws_cloudwatch_metric_alarm" "memoria-alta" {
  count               = (var.enable-ECS && var.enable-alarms) ? 1 : 0
  alarm_name          = "marathon-memoria-alta"
  alarm_description   = "Memoria del servicio por encima del 85% durante 10 minutos"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs-cluster-name
    ServiceName = var.ecs-service-name
  }

  alarm_actions = [aws_sns_topic.alertas[0].arn]
  tags          = local.tags

  depends_on = [aws_ecs_service.ecs-service-one]
}
