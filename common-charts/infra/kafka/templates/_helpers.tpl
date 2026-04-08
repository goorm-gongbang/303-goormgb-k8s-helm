{{/*
Kafka fullname
*/}}
{{- define "kafka.fullname" -}}
{{- default "kafka" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Kafka headless service name
*/}}
{{- define "kafka.headless" -}}
{{ include "kafka.fullname" . }}-headless
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka.labels" -}}
app: {{ include "kafka.fullname" . }}
app.kubernetes.io/name: kafka
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: broker
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka.selectorLabels" -}}
app: {{ include "kafka.fullname" . }}
{{- end }}

{{/*
Generate controller quorum voters string
*/}}
{{- define "kafka.controllerQuorumVoters" -}}
{{- if .Values.config.controllerQuorumVoters }}
{{- .Values.config.controllerQuorumVoters }}
{{- else }}
{{- $voters := list }}
{{- $headless := include "kafka.headless" . }}
{{- range $i := until (int .Values.replicas) }}
{{- $voters = append $voters (printf "%d@%s-%d.%s.%s.svc.cluster.local:9093" (add $i 1) (include "kafka.fullname" $) $i $headless $.Release.Namespace) }}
{{- end }}
{{- join "," $voters }}
{{- end }}
{{- end }}

{{/*
Generate advertised listeners for a specific broker
*/}}
{{- define "kafka.advertisedListeners" -}}
{{- if .Values.config.advertisedListeners }}
{{- .Values.config.advertisedListeners }}
{{- else }}
{{- $headless := include "kafka.headless" . }}
PLAINTEXT://$(POD_NAME).{{ $headless }}.{{ .Release.Namespace }}.svc.cluster.local:9092
{{- end }}
{{- end }}
