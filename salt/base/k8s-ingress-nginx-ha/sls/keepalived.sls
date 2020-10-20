k8s_ha_keepalived_pkgs:
  pkg.installed:
    - pkgs:
      - keepalived

k8s_ha_keepalived_dir:
  file.directory:
    - name: /etc/keepalived/keepalived.d
    - user: root
    - group: root
    - dir_mode: 755

k8s_ha_keepalived_config:
  file.managed:
    - name: /etc/keepalived/keepalived.conf
    - source: salt://k8s-ingress-nginx-ha/templates/keepalived.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: k8s_ha_keepalived_pkgs
      - file: k8s_ha_keepalived_dir

k8s_ha_keepalived_ingress_nginx_config:
  file.managed:
    - name: /etc/keepalived/keepalived.d/ingress-nginx.conf
    - source: salt://k8s-ingress-nginx-ha/templates/keepalived-ingress-nginx.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: k8s_ha_keepalived_config

k8s_ha_keepalived_service:
  service.running:
    - name: keepalived
    - enable: True
    - require:
      - file: k8s_ha_keepalived_config
      - file: k8s_ha_keepalived_ingress_nginx_config
    - watch:
      - file: k8s_ha_keepalived_config
      - file: k8s_ha_keepalived_ingress_nginx_config