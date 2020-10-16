{% set kubelet_dirs = ['pki', 'manifests'] %}

{% for dir in kubelet_dirs %}
kubelet_dirs:
  file.directory:
    - name: /etc/kubernetes/{{ dir }}
    - user: root
    - group: root
    - dir_mode: 755
    - makedirs: True
{% endfor %}

kubelet_kubeconfig:
  file.managed:
    - name: /etc/kubernetes/kubelet-bootstrap.kubeconfig
    - source: salt://k8s-worker/files/kubeconfig/kubelet-bootstrap.kubeconfig
    - user: root
    - group: root
    - mode: 644

kubelet_config:
  file.managed:
    - name: /etc/kubernetes/kubelet-config.yaml
    - source: salt://k8s-worker/files/template/kubelet-config.yaml.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644

kubelet_service_config:
  file.managed:
    - name: /usr/lib/systemd/system/kubelet.service
    - source: salt://k8s-worker/files/templates/kubelet.service.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: kubelet_kubeconfig
      - file: kubelet_config

kubelet_service:
  service.running:
    - name: kubelet
    - enable: True
    - require:
      - file: kubelet_kubeconfig
      - file: kubelet_config
      - file: kubelet_service_config
    - watch:
      - file: kubelet_kubeconfig
      - file: kubelet_config
      - file: kubelet_service_config
