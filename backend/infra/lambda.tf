###############################################################################
# IMPORTACION PERIODICA CON LAMBDA Y EVENTBRIDGE
#
# Funcion que importa carreras desde un fichero JSON depositado en S3 y publica
# un resumen en SNS. La invoca EventBridge una vez por semana.
#
# Es el desarrollo de la funcionalidad opcional prevista en el planteamiento
# inicial del proyecto, y ocupa la carpeta lambdas/import-races que hasta ahora
# estaba vacia.
#
# DECISION DE DISENO: la funcion se ejecuta FUERA de la VPC.
#
# Ubicarla dentro de la subred privada obligaria a anadir VPC endpoints de tipo
# Interface para SNS y para Lambda, con su coste correspondiente por hora y por
# zona. Fuera de la VPC alcanza S3, DynamoDB y SNS por sus interfaces publicas
# usando las credenciales del rol, sin coste adicional de red.
#
# El compromiso es aceptable porque la funcion no accede a ningun recurso
# privado: solo a servicios gestionados. El backend, que si necesita
# aislamiento por ser accesible desde internet, permanece en la subred privada.
###############################################################################


## VARIABLES ##

variable "enable-lambda" {
  description = "Crear la funcion de importacion y su programacion"
  type        = bool
  default     = true
}

variable "lambda-name" {
  description = "Nombre de la funcion de importacion"
  type        = string
  default     = "marathon-import-races"
}

variable "lambda-schedule" {
  description = "Programacion en formato cron de EventBridge (UTC)"
  type        = string
  default     = "cron(0 6 ? * MON *)" # todos los lunes a las 06:00 UTC
}

variable "lambda-import-key" {
  description = "Ruta dentro del bucket del fichero JSON a importar"
  type        = string
  default     = "imports/races.json"
}





## EMPAQUETADO DEL CODIGO ##
#
# El proveedor archive comprime el directorio de la funcion en un .zip durante
# el plan, sin necesitar herramientas externas. No hay dependencias que
# empaquetar: el SDK de AWS v3 viene incluido en el runtime de Node.js.

data "archive_file" "import-races" {
  count       = var.enable-lambda ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/import-races"
  output_path = "${path.module}/.terraform/import-races.zip"
  excludes    = ["README.md", "ejemplo-races.json"]
}





## FUNCION LAMBDA ##

resource "aws_lambda_function" "import-races" {
  count = var.enable-lambda ? 1 : 0

  function_name = var.lambda-name
  description   = "Importa carreras desde un fichero JSON en S3 hacia DynamoDB"

  role    = data.aws_iam_role.lab-role.arn
  runtime = "nodejs20.x"
  handler = "index.handler"

  filename         = data.archive_file.import-races[0].output_path
  source_code_hash = data.archive_file.import-races[0].output_base64sha256

  # 60 s es holgado: el trabajo real son unas decenas de escrituras en DynamoDB.
  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      TABLE_NAME    = var.dynamodb-name
      BUCKET_NAME   = aws_s3_bucket.s3-website.id
      IMPORT_KEY    = var.lambda-import-key
      SNS_TOPIC_ARN = var.enable-alarms ? aws_sns_topic.alertas[0].arn : ""
    }
  }

  tags = local.tags
}

# Grupo de logs propio, con retencion limitada. Sin este recurso Lambda crea el
# grupo automaticamente pero con retencion infinita, lo que acumula coste de
# almacenamiento indefinidamente.
resource "aws_cloudwatch_log_group" "import-races" {
  count             = var.enable-lambda ? 1 : 0
  name              = "/aws/lambda/${var.lambda-name}"
  retention_in_days = 14
  tags              = local.tags
}





## PROGRAMACION CON EVENTBRIDGE ##

resource "aws_cloudwatch_event_rule" "import-races-semanal" {
  count               = var.enable-lambda ? 1 : 0
  name                = "${var.lambda-name}-semanal"
  description         = "Dispara la importacion de carreras una vez por semana"
  schedule_expression = var.lambda-schedule
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "import-races" {
  count     = var.enable-lambda ? 1 : 0
  rule      = aws_cloudwatch_event_rule.import-races-semanal[0].name
  target_id = "lambda"
  arn       = aws_lambda_function.import-races[0].arn
}

# EventBridge necesita permiso explicito para invocar la funcion. Sin esto la
# regla se dispara pero la invocacion es rechazada, y el fallo es silencioso:
# no aparece en los logs de la funcion porque nunca llega a ejecutarse.
resource "aws_lambda_permission" "eventbridge" {
  count         = var.enable-lambda ? 1 : 0
  statement_id  = "PermitirInvocacionDesdeEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.import-races[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.import-races-semanal[0].arn
}
