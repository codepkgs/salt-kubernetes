k8s_ha_nginx_pkgs:
  pkg.installed:
    - pkgs:
      - nginx
      - nginx-mod-stream

k8s_ha_nginx_dirs:
  file.directory:
    - name: /etc/nginx/stream.d
    - user: root
    - group: root
    - dir_mode: 755

k8s_ha_nginx_config:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://k8s-ingress-nginx-ha/templates/nginx.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: k8s_ha_nginx_pkgs
      - file: k8s_ha_nginx_dirs

k8s_ha_nginx_stream_config:
  file.managed:
    - name: /etc/nginx/stream.d/ingress-nginx.conf
    - source: salt://k8s-ingress-nginx-ha/templates/ingress-nginx.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: k8s_ha_nginx_dirs

k8s_ha_nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - file: k8s_ha_nginx_config
      - file: k8s_ha_nginx_stream_config
    - watch:
      - file: k8s_ha_nginx_config
      - file: k8s_ha_nginx_stream_config