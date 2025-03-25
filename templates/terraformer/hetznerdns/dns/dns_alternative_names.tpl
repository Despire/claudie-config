{{- $specName          := .Data.Provider.SpecName }}
{{- $uniqueFingerPrint := .Fingerprint }}
{{- $resourceSuffix    := printf "%s_%s" $specName $uniqueFingerPrint }}
{{- $clusterID 	       := printf "%s-%s" .Data.ClusterName .Data.ClusterHash }}

{{- if hasExtension .Data "AlternativeNamesExtension" }}
	{{- range $_, $alternativeName := .Data.AlternativeNamesExtension.Names }}
	{{- $escapedAlternativeName    := replaceAll $alternativeName "." "_" }}


        {{- range $ip := $.Data.RecordData.IP }}
            {{- $escapedIPv4 := replaceAll $ip.V4 "." "_" }}
            {{- $recordResourceName := printf "record_%s_%s_%s" $escapedAlternativeName $escapedIPv4 $resourceSuffix }}

            resource "hetznerdns_record" "{{ $recordResourceName }}" {
                provider = hetznerdns.hetzner_dns_{{ $resourceSuffix }}
                zone_id = data.hetznerdns_zone.hetzner_zone_{{ $resourceSuffix }}.id
                name = "{{ $alternativeName }}"
                value = "{{ $ip.V4 }}"
                type = "A"
                ttl = 300
            }
        {{- end }}


	output "{{ $clusterID }}_{{ $escapedAlternativeName }}_{{ $resourceSuffix }}" {
	  value = { "{{ $clusterID }}-{{ $alternativeName }}-endpoint" = format("%s.%s", "{{ $alternativeName }}", "{{ $.Data.DNSZone }}")}
	}

	{{- end }}
{{- end }}
