variable "provider_version" {
  description = "The version of the provider to use."
  type        = string
  default     = "0.1.2"
}

provider "hcloud" {
  token = "{{ $.Provider.Credentials }}"
  alias = "nodepool_{{ $.Provider.SpecName }}_${var.provider_version}"
}