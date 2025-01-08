{{/*
Find a graphite-remote-adapter image in various places.
Image can be found from default values .Values.image
*/}}
{{- define "graphite_remote_adapter.image" -}}
    {{- printf "%s" (.Values.graphite_remote_adapter.image) -}}
{{- end -}}
