{{/*
Expand the name of the chart.
*/}}
{{- define "marathon-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "marathon-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" (include "marathon-app.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "marathon-app.labels" -}}
app.kubernetes.io/name: {{ include "marathon-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "marathon-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "marathon-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
