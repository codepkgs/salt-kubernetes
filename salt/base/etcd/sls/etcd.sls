{% set etcd_data_dir = salt['pillar.get']('etcd_data_dir', '/var/lib/etcd/defaults.etcd') %}
{% set etcd_field_map = {
  'etcd_cert_content': 'etcd.pem',
  'etcd_key_content': 'etcd-key.pem',
  'etcd_trusted_ca_content': 'ca.pem',
  'etcd_peer_cert_content': 'etcd-peer-cert.pem',
  'etcd_peer_key_content': 'etcd-peer-key.pem',
  'etcd_peer_trusted_ca_content': 'ca-peer.pem'
} %}

etcd_pkg:
  pkg.installed:
    - order: 1
    - pkgs:
      - etcd

etcd_data_dir:
  file.directory:
    - order: 2
    - name: {{ etcd_data_dir }}
    - user: etcd
    - group: etcd
    - dir_mode: 755
    - makedirs: True

{% for field in etcd_field_map %}
{% if salt['pillar.get'](field, False) %}
etcd_certs_{{ etcd_field_map[field] }}:
  file.managed:
    - order: 3
    - name: /etc/etcd/certs/{{ etcd_field_map[field] }}
    - contents_pillar: {{ field }}
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
{% endif %}
{% endfor %}

etcd_config:
  file.managed:
    - order: 4
    - name: /etc/etcd/etcd.conf
    - source: salt://etcd/templates/etcd.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: etcd_pkg
      {% for field in etcd_field_map %}
      {% if salt['pillar.get'](field, False) %}
      - file: etcd_certs_{{ etcd_field_map[field] }}
      {% endif %}
      {% endfor %}

etcd_service:
  service.running:
    - order: 5
    - name: etcd
    - enable: True
    - require:
      - file: etcd_config
      {% for field in etcd_field_map %}
      {% if salt['pillar.get'](field, False) %}
      - file: etcd_certs_{{ etcd_field_map[field] }}
      {% endif %}
      {% endfor %}
    - watch:
      - file: etcd_config
      {% for field in etcd_field_map %}
      {% if salt['pillar.get'](field, False) %}
      - file: etcd_certs_{{ etcd_field_map[field] }}
      {% endif %}
      {% endfor %}
