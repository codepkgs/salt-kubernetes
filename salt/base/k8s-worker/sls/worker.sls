{% set k8s_pkg_url = 'https://devops.maka.im/kubernetes/v1.16.9/bin' %}
{% set worker_pkgs = ['kubelet', 'kube-proxy', 'kubectl'] %}
{% set dirs = ['/etc/kubernetes/certs', '/var/log/kubernetes'] %}

{% for package in worker_pkgs %}
worker_pkg_{{ package }}:
  file.managed:
    - name: /usr/bin/{{ package }}
    - source: {{ k8s_pkg_url }}/{{ package }}
    - user: root
    - group: root
    - mode: 755
    - skip_verify: True
{% endfor %}

{% for dir in dirs %}
worker_dir_{{ dir }}:
  file.directory:
    - name: {{ dir }}
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
{% endfor %}

{# certs #}
worker_certs:
  file.recurse:
    - name: /etc/kubernetes/certs
    - source: salt://k8s-worker/files/certs
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644