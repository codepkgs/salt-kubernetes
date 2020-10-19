{% set cni_url = 'https://devops.maka.im/kubernetes/cni' %}
{% set cni_version = 'cni-plugins-linux-amd64-v0.8.5.tgz' %}

cni_bins:
  archive.extracted:
    - name: /opt/cni/bin
    - source: {{ cni_url }}/{{ cni_version }}
    - user: root
    - group: root
    - skip_verify: True
