controller_manager_kubeconfig:
  file.managed:
    - name: /etc/kubernetes/kube-controller-manager.kubeconfig
    - source: salt://k8s-master/files/kubeconfig/kube-controller-manager.kubeconfig
    - user: root
    - group: root
    - mode: 644

controller_manager_service_config:
  file.managed:
    - name: /usr/lib/systemd/system/kube-controller-manager.service
    - source: salt://k8s-master/files/services/kube-controller-manager.service.j2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: controller_manager_kubeconfig

controller_manager_service:
  service.running:
    - name: kube-controller-manager
    - enable: True
    - require:
      - file: controller_manager_kubeconfig
      - file: controller_manager_service_config
    - watch:
      - file: controller_manager_kubeconfig
      - file: controller_manager_service_config
