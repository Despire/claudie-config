provider "hcloud" {
  token = "{{ $.Provider.Credentials }}"
  alias = "nodepool_{{ $.Provider.SpecName }}_v0.1.2"
}