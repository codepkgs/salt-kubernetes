kube_proxy_kubeconfig:
  file.managed:
    - name: /etc/kubernetes/kube-proxy.kubeconfig
    - source: salt://k8s-worker/files/kubeconfig/kube-proxy.kubeconfig
    - user: root
    - group: root
    - mode: 644

kube_proxy_config:
  file.managed:
    - name: /etc/kubernetes/kube-proxy.yaml
    - source: salt://k8s-worker/templates/kube-proxy.yaml.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: kube_proxy_kubeconfig

kube_proxy_service_config:
  file.managed:
    - name: /usr/lib/systemd/system/kube-proxy.service
    - source: salt://k8s-worker/templates/kube-proxy.service
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: kube_proxy_kubeconfig
      - file: kube_proxy_config

kube_proxy_service:
  service.running:
    - name: kube-proxy
    - enable: True
    - require:
      - file: kube_proxy_kubeconfig
      - file: kube_proxy_config
      - file: kube_proxy_service_config
    - watch:
      - file: kube_proxy_kubeconfig
      - file: kube_proxy_config
      - file: kube_proxy_service_config
