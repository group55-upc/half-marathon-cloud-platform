enable-ECS = true


###############################################################################
# PLANTILLA DE VARIABLES LOCALES
#
# Copia este archivo como 'terraform.tfvars' y rellenalo con tus valores.
#
#   Copy-Item terraform.tfvars.example terraform.tfvars    (PowerShell)
#   cp terraform.tfvars.example terraform.tfvars           (Linux / macOS)
#
# 'terraform.tfvars' esta en el .gitignore y NO se sube al repositorio.
#
# POR QUE: las direcciones de correo del equipo son datos personales. Dejarlas
# en un archivo versionado las expone a quien tenga acceso al repositorio y a
# los rastreadores de spam que recorren GitHub. Terraform carga 'terraform.tfvars'
# automaticamente, sin necesidad de pasar nada por linea de comandos.
#
# Es el mismo patron que ya usa Miquel/infrastructure/terraform.
###############################################################################


# Correos que recibiran las alarmas de CloudWatch.
#
# Cada direccion recibira un mensaje de AWS con un enlace "Confirm
# subscription" que debe pulsar. Hasta entonces no le llegara ninguna alarma.
# alert-emails = [
#   "tu.correo@ejemplo.com",
# ]


# --- Ajustes opcionales del escalado automatico ---
#
# Descomenta y modifica solo si quieres cambiar los valores por defecto.

# ecs-autoscaling-min        = 2
# ecs-autoscaling-max        = 4
# ecs-autoscaling-cpu-target = 70


# --- Interruptores de los bloques opcionales ---
#
# Poner a false si el laboratorio deniega algun permiso y hay que desplegar
# sin esa pieza concreta.

# enable-autoscaling = true
# enable-alarms      = true
# enable-lambda      = true


# --- Programacion de la importacion periodica ---
#
# Formato cron de EventBridge, en UTC. Por defecto los lunes a las 06:00.

# lambda-schedule = "cron(0 6 ? * MON *)"