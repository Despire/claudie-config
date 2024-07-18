{{- $clusterName       := .Data.ClusterData.ClusterName}}
{{- $clusterHash       := .Data.ClusterData.ClusterHash}}
{{- $uniqueFingerPrint := .Fingerprint }}

{{- range $_, $nodepool := .Data.NodePools }}

{{- $region   := $nodepool.NodePool.Region }}
{{- $specName := $nodepool.NodePool.Provider.SpecName }}

{{- range $node := $nodepool.Nodes }}
resource "google_compute_instance" "{{ $node.Name }}_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}" {
  provider                  = google.nodepool_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}
  zone                      = "{{ $nodepool.NodePool.Zone }}"
  name                      = "{{ $node.Name }}"
  machine_type              = "{{ $nodepool.NodePool.ServerType }}"
  description   = "Managed by Claudie for cluster {{ $clusterName }}-{{ $clusterHash }}"
  allow_stopping_for_update = true

  network_interface {
    subnetwork = google_compute_subnetwork.{{ $nodepool.Name }}_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}_subnet.self_link
    access_config {}
  }

  metadata = {
    ssh-keys = "root:${file("./{{ $nodepool.Name }}")}"
  }

  labels = {
    managed-by = "claudie"
    claudie-cluster = "{{ $clusterName }}-{{ $clusterHash }}"
  }

{{- if eq $.Data.ClusterData.ClusterType "LB" }}
  boot_disk {
    initialize_params {
      size = "50"
      image = "{{ $nodepool.NodePool.Image }}"
    }
  }
  metadata_startup_script = "echo 'PermitRootLogin without-password' >> /etc/ssh/sshd_config && echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && service sshd restart"
{{- end }}

{{- if eq $.Data.ClusterData.ClusterType "K8s" }}
  boot_disk {
    initialize_params {
      size = "100"
      image = "{{ $nodepool.NodePool.Image }}"
    }
  }

  metadata_startup_script = <<EOF
  #!/bin/bash
  set -euxo pipefail
# Allow ssh as root
echo 'PermitRootLogin without-password' >> /etc/ssh/sshd_config && echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && service sshd restart  
# Create longhorn volume directory
mkdir -p /opt/claudie/data
    {{- if and (not $nodepool.IsControl) (gt $nodepool.NodePool.StorageDiskSize 0) }}
# Mount managed disk only when not mounted yet
sleep 50
disk=$(ls -l /dev/disk/by-id | grep "google-${var.gcp_storage_disk_name_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}}" | awk '{print $NF}')
disk=$(basename "$disk")
if ! grep -qs "/dev/$disk" /proc/mounts; then
  if ! blkid /dev/$disk | grep -q "TYPE=\"xfs\""; then
    mkfs.xfs /dev/$disk
  fi
  mount /dev/$disk /opt/claudie/data
  echo "/dev/$disk /opt/claudie/data xfs defaults 0 0" >> /etc/fstab
fi
    {{- end }}
EOF

  {{- if and (not $nodepool.IsControl) (gt $nodepool.NodePool.StorageDiskSize 0) }}
  # As the storage disk is attached via google_compute_attached_disk,
  # we must ignore attached_disk property.
  lifecycle {
    ignore_changes = [attached_disk]
  }
  {{- end }}

{{- end }}
}

{{- if eq $.Data.ClusterData.ClusterType "K8s" }}
    {{- if and (not $nodepool.IsControl) (gt $nodepool.NodePool.StorageDiskSize 0) }}
resource "google_compute_disk" "{{ $node.Name }}_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}_disk" {
  provider = google.nodepool_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}
  # suffix 'd' as otherwise the creation of the VM instance and attachment of the disk will fail, if having the same name as the node.
  name     = "{{ $node.Name }}d"
  type     = "pd-ssd"
  zone     = "{{ $nodepool.NodePool.Zone }}"
  size     = {{ $nodepool.NodePool.StorageDiskSize }}

  labels = {
    managed-by = "claudie"
    claudie-cluster = "{{ $clusterName }}-{{ $clusterHash }}"
  }
}

resource "google_compute_attached_disk" "{{ $node.Name }}_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}_disk_att" {
  provider    = google.nodepool_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}
  disk        = google_compute_disk.{{ $node.Name }}_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}_disk.id
  instance    = google_compute_instance.{{ $node.Name }}_{{ $region}}_{{ $specName }}_{{ $uniqueFingerPrint }}.id
  zone        = "{{ $nodepool.NodePool.Zone }}"
  device_name = var.gcp_storage_disk_name_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}
}
    {{- end }}
{{- end }}

{{- end }}

output "{{ $nodepool.Name }}_{{ $uniqueFingerPrint }}" {
  value = {
  {{- range $node := $nodepool.Nodes }}
    "${google_compute_instance.{{ $node.Name }}_{{ $region}}_{{ $specName }}_{{ $uniqueFingerPrint }}.name}" = google_compute_instance.{{ $node.Name }}_{{ $region }}_{{ $specName }}_{{ $uniqueFingerPrint }}.network_interface.0.access_config.0.nat_ip
  {{- end }}
  }
}
{{- end }}
