scheduler_kubeconfig:
  file.managed:
    - name: /etc/kubernetes/kube-scheduler.kubeconfig
    - source: salt://k8s-master/files/kubeconfig/kube-scheduler.kubeconfig
    - user: root
    - group: root
    - mode: 644

scheduler_service_config:
  file.managed:
    - name: /usr/lib/systemd/system/kube-scheduler.service
    - source: salt://k8s-master/files/services/kube-scheduler.service
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: scheduler_kubeconfig

scheduler_service:
  service.running:
    - name: kube-scheduler
    - enable: True
    - require:
      - file: scheduler_kubeconfig
      - file: scheduler_service_config
    - watch:
      - file: scheduler_kubeconfig
      - file: scheduler_service_config
