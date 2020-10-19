k8s_ha_keepalived_pkgs:
  pkg.installed:
    - pkgs:
      - keepalived

k8s_ha_keepalived_chk_script:
  file.managed:
    - name: /etc/keepalived/chk_nginx.sh
    - source: salt://k8s-ha/files/chk_nginx.sh
    - user: root
    - group: root
    - mode: 755

k8s_ha_keepalived_config:
  file.managed:
    - name: /etc/keepalived/keepalived.conf
    - source: salt://k8s-ha/templates/keepalived.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: k8s_ha_keepalived_pkgs
      - file: k8s_ha_keepalived_chk_script

k8s_ha_keepalived_service:
  service.running:
    - name: keepalived
    - enable: True
    - require:
      - file: k8s_ha_keepalived_config
    - watch:
      - file: k8s_ha_keepalived_config