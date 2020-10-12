{% set cfssl_url = 'https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl_1.4.1_linux_amd64' %}
{% set cfssljson_url = 'https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssljson_1.4.1_linux_amd64' %}
{% set cfssl_url_map = {'cfssl': cfssl_url, 'cfssljson': cfssljson_url } %}
{% set cfssl_default_configs = ['ca-csr.json', 'config.json'] %}
{% set cfssl_dirs = ['configs', 'certs'] %}

{% for name, url in cfssl_url_map.items() %}
cfssl_{{ name }}:
  file.managed:
    - name: /usr/local/bin/{{ name }}
    - source: {{ url }}
    - skip_verify: True
    - keep_source: True
    - user: root
    - group: root
    - mode: 755
    - unless: test -x /usr/local/bin/{{ name }}
{% endfor %}

{% for dir in cfssl_dirs %}
cfssl_dir_{{ dir }}:
  file.directory:
    - name: /etc/cfssl/{{ dir }}
    - user: root
    - group: root
    - dir_mode: 755
    - makedirs: True
{% endfor %}

{% for config in cfssl_default_configs %}
cfssl_default_config_{{ config }}:
  file.managed:
    - name: /etc/cfssl/configs/{{ config }}
    - source: salt://cfssl/files/{{ config }}.j2
    - user: root
    - group: root
    - mode: 644
    - template: jinja
{% endfor %}