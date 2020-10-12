{%if grains['os_family'].lower() == 'redhat' %}
resolv_config:
  file.managed:
    - name: /etc/resolv.conf
    - template: jinja
    - source: salt://resolv/files/resolv.conf.j2
    - user: root
    - group: root
    - mode: 0644
  {% endif %}