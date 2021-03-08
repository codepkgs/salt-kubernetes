{% set k8s_pkg_url = 'https://devops.maka.im/kubernetes/v1.20.4/bin' %}
{% set master_pkgs = ['kube-apiserver', 'kube-controller-manager', 'kube-scheduler', 'kubelet', 'kube-proxy', 'kubeadm', 'kubectl'] %}
{% set dirs = ['/etc/kubernetes/certs', '/var/log/kubernetes'] %}

{% for package in master_pkgs %}
master_pkg_{{ package }}:
  file.managed:
    - name: /usr/bin/{{ package }}
    - source: {{ k8s_pkg_url }}/{{ package }}
    - user: root
    - group: root
    - mode: 755
    - skip_verify: True
{% endfor %}

{% for dir in dirs %}
master_dir_{{ dir }}:
  file.directory:
    - name: {{ dir }}
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
{% endfor %}

{# certs #}
master_certs:
  file.recurse:
    - name: /etc/kubernetes/certs
    - source: salt://k8s-master/files/certs
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
