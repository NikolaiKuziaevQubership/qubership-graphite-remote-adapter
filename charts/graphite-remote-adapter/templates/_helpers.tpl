{{/*
Find a graphite-remote-adapter image in various places.
Image can be found from default values .Values.image
*/}}
{{- define "graphite_remote_adapter.image" -}}
  {{- if .Values.image -}}
    {{- printf "%s" .Values.image -}}
  {{- else -}}
    {{- print "ghcr.io/netcracker/qubership-graphite-remote-adapter:main" -}}
  {{- end -}}
{{- end -}}

