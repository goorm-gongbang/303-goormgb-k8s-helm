{{/*
Expand the name of the chart.
*/}}
{{- define "java-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Release.Name만 사용 (dev-order-core-java-service → dev-order-core)
*/}}
{{- define "java-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "java-service.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "java-service.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels (immutable - 변경 금지)
주의: 이 라벨들은 Deployment selector에 사용되므로 절대 변경하면 안됨!
*/}}
{{- define "java-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "java-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .Values.component | default "backend" }}
app: {{ .Release.Name }}
{{- end }}

{{/*
Pod labels (selectorLabels + 추가 라벨)
이 라벨들은 pod template에만 사용되므로 변경 가능
*/}}
{{- define "java-service.podLabels" -}}
{{ include "java-service.selectorLabels" . }}
app.kubernetes.io/part-of: {{ .Values.partOf | default "staging-webs" }}
{{- end }}

{{/*
Version label (Istio 트래픽 관리용)
*/}}
{{- define "java-service.versionLabel" -}}
version: {{ .Values.image.tag | default "latest" | quote }}
{{- end }}
