{{/*
Expand the name of the chart.
*/}}
{{- define "backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "backend.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "backend.labels" -}}
helm.sh/chart: {{ include "backend.chart" . }}
{{ include "backend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
LLM proxy fullname.
*/}}
{{- define "backend.llmProxyFullname" -}}
{{- printf "%s-llm-proxy" (include "backend.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Selector labels dedicated to llm-proxy pods/services.
*/}}
{{- define "backend.llmProxySelectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}-llm-proxy
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Celery worker fullname.
*/}}
{{- define "backend.celeryWorkerFullname" -}}
{{- printf "%s-celery-worker" (include "backend.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Selector labels dedicated to celery worker pods.
*/}}
{{- define "backend.celeryWorkerSelectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}-celery-worker
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Redis host for backend/celery connections.
*/}}
{{- define "backend.redisHost" -}}
{{- if .Values.redis.connection.host -}}
{{- .Values.redis.connection.host -}}
{{- else -}}
{{- printf "%s-redis-master" .Release.Name -}}
{{- end -}}
{{- end }}

{{/*
Nginx static/media fullname.
*/}}
{{- define "backend.nginxFilesFullname" -}}
{{- printf "%s-nginx-files" (include "backend.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Selector labels dedicated to nginx static/media pods/services.
*/}}
{{- define "backend.nginxFilesSelectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}-nginx-files
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

