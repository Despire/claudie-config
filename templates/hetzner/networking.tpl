{{- $clusterName := .Data.ClusterData.ClusterName }}
{{- $clusterHash := .Data.ClusterData.ClusterHash }}

{{- $specName := $.Data.Provider.SpecName }}

resource "hcloud_ssh_key" "claudie_{{ $specName }}" {
  provider   = hcloud.nodepool_{{ $specName }}_{{ $.Fingerprint}}
  name       = "key-{{ $clusterHash }}-{{ $specName }}"
  public_key = file("./public.pem")

  labels = {
    "managed-by"      : "Claudie"
    "claudie-cluster" : "{{ $clusterName }}-{{ $clusterHash }}"
  }
}

resource "hcloud_firewall" "firewall_{{ $specName }}" {
  provider = hcloud.nodepool_{{ $specName }}_{{ $.Fingerprint }}
  name     = "fwl-{{ $clusterHash }}-{{ $specName }}"
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "51820"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

{{- if eq $.Data.ClusterData.ClusterType "LB" }}
  {{- range $role := index $.Data.Metadata "roles" }}
  rule {
    direction  = "in"
    protocol   = "{{ $role.Protocol }}"
    port       = "{{ $role.Port }}"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  {{- end }}
{{- end }}

{{- if eq $.Data.ClusterData.ClusterType "K8s" }}
  {{- if index $.Data.Metadata "loadBalancers" | targetPorts | isMissing 6443 }}
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  {{- end }}
{{- end }}

  labels = {
    "managed-by"      : "Claudie"
    "claudie-cluster" : "{{ $clusterName }}-{{ $clusterHash }}"
  }
}