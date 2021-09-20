{{/* vim: set filetype=mustache: */}}
{{/*
The name of the chart, truncated to 63 chars. Override via nameOverride.
*/}}
{{- define "fhir.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
A fully qualified app name for uniquely identifying resources from this chart
for a particular release. Override via fullnameOverride.
We truncate at 63 chars because some Kubernetes name fields are limited to this
(by the DNS naming spec).
*/}}
{{- define "fhir.fullname" -}}
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
Return the appropriate apiVersion for ingress.
*/}}
{{- define "fhir.ingressAPIVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
{{- print "networking.k8s.io/v1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified PostgreSQL name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
NOTE: we should be able to replace this approach once https://github.com/helm/helm/pull/9957 is available in Helm
*/}}
{{- define "fhir.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get the database server's hostname
*/}}
{{- define "fhir.database.host" -}}
{{- ternary (include "fhir.postgresql.fullname" .) .Values.db.host .Values.postgresql.enabled -}}
{{- end -}}

{{/*
Get the user to connect to the database server
*/}}
{{- define "fhir.database.user" -}}
{{- ternary .Values.postgresql.postgresqlUsername .Values.db.user .Values.postgresql.enabled -}}
{{- end -}}

{{/*
Get the name of the database
*/}}
{{- define "fhir.database.name" -}}
{{- ternary .Values.postgresql.postgresqlDatabase .Values.db.database .Values.postgresql.enabled -}}
{{- end -}}

{{/*
Get the database server's port
*/}}
{{- define "fhir.database.port" -}}
{{- ternary "5432" .Values.db.port .Values.postgresql.enabled -}}
{{- end -}}

{{/*
Get the database credentials secret name.
*/}}
{{- define "fhir.database.secretName" -}}
{{- if and (.Values.postgresql.enabled) (not .Values.postgresql.existingSecret) -}}
    {{- printf "%s" (include "fhir.postgresql.fullname" .) -}}
{{- else if and (.Values.postgresql.enabled) (.Values.postgresql.existingSecret) -}}
    {{- printf "%s" .Values.postgresql.existingSecret -}}
{{- else if .Values.db.dbSecret -}}
    {{- printf "%s" .Values.db.dbSecret -}}
{{- else -}}
    {{- printf "%s-%s" (include "fhir.fullname" .) "db-secret" -}}
{{- end -}}
{{- end -}}

{{/*
Get the database credentials password secret key.
*/}}
{{- define "fhir.database.passwordSecretKey" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "postgresql-password" -}}
{{- else if (.Values.db.dbSecret) -}}
    {{- printf "%s" .Values.db.passwordSecretKey -}}
{{- else }}
    {{- printf "password" -}}
{{- end -}}
{{- end -}}

{{/*
Get the database credentials apiKey secret key.
*/}}
{{- define "fhir.database.apiKeySecretKey" -}}
{{- if (.Values.db.dbSecret) -}}
    {{- printf "%s" .Values.db.apiKeySecretKey -}}
{{- else }}
    {{- printf "apiKey" -}}
{{- end -}}
{{- end -}}

{{/*
Image used to for the PostgreSQL readiness init containers
If using Helm 3.7+, we could use `include "postgresql.image" .Subcharts.postgresql` instead
*/}}
{{- define "fhir.postgresql.waitForDB.image" -}}
{{- printf "%s/%s:%s" .Values.postgresql.image.registry .Values.postgresql.image.repository .Values.postgresql.image.tag }}
{{- end -}}
