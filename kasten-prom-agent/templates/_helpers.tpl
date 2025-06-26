{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus-agent-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "prometheus-agent-chart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as a label
*/}}
{{- define "prometheus-agent-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "prometheus-agent-chart.labels" -}}
helm.sh/chart: {{ include "prometheus-agent-chart.chart" . }}
{{ include "prometheus-agent-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "prometheus-agent-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "prometheus-agent-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Validate chart values.
This template contains all complex conditional validation logic for the chart.
*/}}
{{- define "kasten-prom-agent.validateValues" -}}
  {{- $errors := list -}} # Changed from [] to list for robustness

  {{- /* Get authentication flags */ -}}
  {{- $basicAuthEnabled := .Values.remoteWrite.basicAuth.enabled -}}
  {{- $bearerTokenEnabled := .Values.remoteWrite.bearerToken.enabled -}}

  {{- /* Validation Rule 1: Mutual Exclusivity for basicAuth and bearerToken */ -}}
  {{- if and $basicAuthEnabled $bearerTokenEnabled }}
    {{- $errors = append $errors "Error: remoteWrite.basicAuth.enabled and remoteWrite.bearerToken.enabled are mutually exclusive. Only one can be true at a time. Please choose one authentication method." }}
  {{- end }}

  {{- /* Validation Rule 2: basicAuth.passwordSecretName required if basicAuth.enabled */ -}}
  {{- if and $basicAuthEnabled (not .Values.remoteWrite.basicAuth.passwordSecretName) }}
    {{- $errors = append $errors "Error: When remoteWrite.basicAuth.enabled is true, remoteWrite.basicAuth.passwordSecretName must be provided and cannot be empty. Please specify the name of the Kubernetes Secret for the basic auth password." }}
  {{- end }}

  {{- /* Validation Rule 3: bearerToken.secretName required if bearerToken.enabled */ -}}
  {{- if and $bearerTokenEnabled (not .Values.remoteWrite.bearerToken.secretName) }}
    {{- $errors = append $errors "Error: When remoteWrite.bearerToken.enabled is true, remoteWrite.bearerToken.secretName must be provided and cannot be empty. Please specify the name of the Kubernetes Secret for the bearer token." }}
  {{- end }}

  {{- /* Validation Rule 4: remoteWrite.url must be set if any auth is enabled */ -}}
  {{- if and (or $basicAuthEnabled $bearerTokenEnabled) (not .Values.remoteWrite.url) }}
    {{- $errors = append $errors "Error: remoteWrite.url must be provided and cannot be empty when remoteWrite.basicAuth or remoteWrite.bearerToken is enabled." }}
  {{- end }}

  {{- /* Validation Rule 5: remoteWrite.url must start with http(s):// */ -}}
  {{- if and .Values.remoteWrite.url (not (hasPrefix "http://" .Values.remoteWrite.url)) (not (hasPrefix "https://" .Values.remoteWrite.url)) }}
    {{- $errors = append $errors "Error: remoteWrite.url must start with 'http://' or 'https://'." }}
  {{- end }}

  {{- /* Validation Rule 6: clusterName must not be empty */ -}}
  {{- if not .Values.clusterName }}
    {{- $errors = append $errors "Error: clusterName must be provided and cannot be empty. This value is used to label metrics for cluster identification. Use --set clusterName to specify a unique clusterName" }}
  {{- end }}

  {{- /* If there are any errors, fail the chart rendering */ -}}
  {{- if gt (len $errors) 0 }}
    {{- fail (join "\n" $errors) }}
  {{- end -}}
{{- end -}}