apiserver_config:
  file.managed:
    - name: /etc/kubernetes/kube-apiserver.conf
    - source: salt://k8s-master/templates/kube-apiserver.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644

apiserver_service_config:
  file.managed:
    - name: /usr/lib/systemd/system/kube-apiserver.service
    - source: salt://k8s-master/files/services/kube-apiserver.service
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: apiserver_config

apiserver_service:
  service.running:
    - name: kube-apiserver
    - enable: True
    - require:
      - file: apiserver_config
      - file: apiserver_service_config
    - watch:
      - file: apiserver_config
      - file: apiserver_service_config