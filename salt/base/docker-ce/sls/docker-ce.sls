{% set kernel_parameters = ['net.bridge.bridge-nf-call-ip6tables', 'net.bridge.bridge-nf-call-iptables'] %}

{% if pillar['docker_users_in_dockergroup'] is defined and pillar['docker_users_in_dockergroup'] %}
    {% set users_in_dockergroup = pillar['docker_users_in_dockergroup'] %}
{% else %}
    {% set users_in_dockergroup = [] %}
{% endif %}

{% if pillar['docker_users_not_in_dockergroup'] is defined and pillar['docker_users_not_in_dockergroup'] %}
    {% set users_not_in_dockergroup = pillar['docker_users_not_in_dockergroup'] %}
{% else %}
    {% set users_not_in_dockergroup = [] %}
{% endif %}

docker_dep_pkgs:
  pkg.installed:
    - pkgs:
      - yum-utils
      - device-mapper-persistent-data
      - lvm2

docker_yum_repo:
  file.managed:
    - name: /etc/yum.repos.d/docker-ce.repo
    - source: salt://docker-ce/files/docker-ce.repo
    - user: root
    - group: root
    - mode: 644

docker_pkgs:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io

docker_daemon_dir:
  file.directory:
    - name: /etc/docker
    - user: root
    - group: root
    - dir_mode: 755

docker_daemon_config:
  file.managed:
    - name: /etc/docker/daemon.json
    - source: salt://docker-ce/files/daemon.json
    - user: root
    - group: root
    - mode: 644

docker_group:
  group.present:
    - name: docker
    - system: True
    - addusers:
    {% for user in users_in_dockergroup %}
      - {{ user }}
    {% endfor %}
    - delusers:
    {% for user in users_not_in_dockergroup %}
      - {{ user }}
    {% endfor %}
      

docker_br_netfilter:
  kmod.present:
    - name: br_netfilter
    - persist: True

{% for parameter in kernel_parameters %}
docker_kernel_{{ parameter }}:
  sysctl.present:
    - name: {{ parameter }}
    - value: "1"
    - config: /etc/sysctl.conf
{% endfor %}

docker_iptables:
  file.line:
    - name: /usr/lib/systemd/system/docker.service
    - content: 'ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT'
    - mode: ensure
    - after: '^ExecStart='

docker_iptables_policy:
  iptables.set_policy:
    - table: filter
    - chain: FORWARD
    - policy: ACCEPT

docker_daemon:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: docker_pkgs
      - file: docker_daemon_config
    - watch:
      - file: docker_daemon_config
      - file: docker_iptables