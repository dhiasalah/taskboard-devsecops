{{/*
Labels for every TaskBoard object (not for selectors: those never change).
*/}}
{{- define "taskboard.labels" -}}
app.kubernetes.io/part-of: taskboard
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
The container lock: the same for all 4 containers.
*/}}
{{- define "taskboard.containerSecurity" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{/*
The name of the database password Secret. Fails loudly if it is empty.
*/}}
{{- define "taskboard.dbSecret" -}}
{{ required "db.existingSecret is empty: create the Secret first, then give its name" .Values.db.existingSecret }}
{{- end }}
