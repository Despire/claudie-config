provider "hcloud" {
  token = "{{ $.Data.Provider.Credentials }}"
  alias = "nodepool_{{ $.Data.Provider.SpecName }}_{{ $.Fingerprint }}"
}