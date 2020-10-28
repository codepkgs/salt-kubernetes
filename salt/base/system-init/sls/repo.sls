{% if 'alibaba' not in grains['productname'].lower() %}
{% if grains['os_family'].lower() == 'redhat' %}
system_init_repo_epel:
  file.managed:
    - name: /etc/yum.repos.d/epel.repo
    - source: salt://system-init/files/epel_{{ grains['osmajorrelease'] }}.repo
    - user: root
    - group: root
    - mode: 0644
{% endif %}

{% if grains['os'].lower() == 'centos' %}
system_init_repo_centos:
  file.managed:
    - name: /etc/yum.repos.d/CentOS-Base.repo
    - source: salt://system-init/files/CentOS-Base_{{ grains['osmajorrelease'] }}.repo
    - user: root
    - group: root
    - mode: 0644
{% endif %}
{% endif %}
