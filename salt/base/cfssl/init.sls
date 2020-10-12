{% set cfssl_cert_ca = salt['pillar.get']('cfssl_cert_ca', True) %}
include:
  - .sls/cfssl
  {% if cfssl_cert_ca %}
  - .sls/cfssl_ca
  {% endif %}