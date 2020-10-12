ntpd_ntp:
  pkg.installed:
    - name: ntp

ntpd_chronyd:
  service.dead:
    - name: chronyd
    - enable: False

ntpd_config:
  file.managed:
    - name: /etc/ntp.conf
    {% if 'alibaba' not in grains['productname'].lower() %}
    - source: salt://ntpd/files/ntp.conf.j2
    {% endif %}
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: ntp

ntpd_service:
  service.running:
    - name: ntpd
    - enable: True
    - watch:
      - file: /etc/ntp.conf

