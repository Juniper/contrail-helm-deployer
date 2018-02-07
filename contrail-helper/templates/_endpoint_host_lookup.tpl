{{/*
Name: contrail-helper.get_endpoint_host
Description: Template for entrypoint init container to check the dependency
Arguements:
  1. context
  2. endpoint name
*/}}

{{- define "contrail-helper.get_endpoint_host" -}}

{{- $context := index . 0 }}
{{- $endpoint_type := index . 1 }}
{{- $endpoint_dict := index $context.Values.endpoints $endpoint_type }}
{{- $cluster_domain := $context.Values.endpoints.cluster_domain }}
{{- $namespace := $endpoint_dict.namespace | default $context.Release.Namespace }}
{{- $endpoint_host := $endpoint_dict.host }}
{{- printf "%s.%s.%s" $endpoint_host $namespace $cluster_domain }}

{{- end }}
