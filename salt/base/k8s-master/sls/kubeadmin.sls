kubeadmin_kubeconfig:
  file.managed:
    - name: /etc/kubernetes/admin.kubeconfig
    - source: salt://k8s-master/files/kubeconfig/admin.kubeconfig
    - user: root
    - group: root
    - mode: 644