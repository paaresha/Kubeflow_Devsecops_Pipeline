{{/*
=============================================================================
Helm Template Helpers — Shared Microservice Chart
=============================================================================
*/}}

{{/*
Full name: <service-name>
*/}}
{{- define "microservice.fullname" -}}
{{- .Values.name -}}
{{- end -}}

{{/*
Common labels applied to all resources
*/}}
{{- define "microservice.labels" -}}
app: {{ .Values.name }}
team: {{ .Values.team }}
version: {{ .Values.version }}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/part-of: kubeflow-ops
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/*
Selector labels (must match between Deployment and Service)
*/}}
{{- define "microservice.selectorLabels" -}}
app: {{ .Values.name }}
{{- end -}}

{{/*
Pod template labels (selectors + extra metadata)
*/}}
{{- define "microservice.podLabels" -}}
app: {{ .Values.name }}
service: {{ .Values.name }}
team: {{ .Values.team }}
version: {{ .Values.version }}
{{- end -}}
