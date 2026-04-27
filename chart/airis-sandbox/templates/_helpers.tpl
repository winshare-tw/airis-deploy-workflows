{{/*
Sandbox resource name: stable, K8s-RFC1123 compliant.
Format: sandbox-<app>-<instance>
e.g. sandbox-airis-webapp-bold-7f3e
*/}}
{{- define "airis-sandbox.fullname" -}}
{{- printf "sandbox-%s-%s" .Values.app .Values.instance | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels — applied to every resource the chart owns.
*/}}
{{- define "airis-sandbox.labels" -}}
app: {{ .Values.app }}
instance: {{ .Values.instance }}
managed-by: airis-deploy-workflows
{{- if and .Values.promote .Values.alias }}
latest: "true"
alias: {{ .Values.alias | quote }}
{{- end }}
{{- end -}}

{{/*
Selector labels — DO NOT include `latest` (label is mutable, selectors are immutable).
*/}}
{{- define "airis-sandbox.selectorLabels" -}}
app: {{ .Values.app }}
instance: {{ .Values.instance }}
{{- end -}}

{{/*
Image reference. Resolves repository default (= app name) when empty.
*/}}
{{- define "airis-sandbox.image" -}}
{{- $repo := default .Values.app .Values.image.repository -}}
{{- printf "%s/%s:%s" .Values.image.registry $repo .Values.image.tag -}}
{{- end -}}

{{/*
Required-value guard. Fails render with a clear message if a value is missing.
*/}}
{{- define "airis-sandbox.requireNonEmpty" -}}
{{- $name := index . 0 -}}
{{- $value := index . 1 -}}
{{- if not $value -}}
{{- fail (printf "airis-sandbox: required value `%s` is empty" $name) -}}
{{- end -}}
{{- end -}}
