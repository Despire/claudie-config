provider "hcloud" {
  token = "{{ $.Data.Provider.Credentials }}"
  alias = "nodepool_{{ $.Provider.SpecName }}_{{ $.Fingerprint }}"
}