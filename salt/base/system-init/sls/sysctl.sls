{% for line in pillar['sysctl_configs'] %}
{{ line.key }}:
  sysctl.present:
    - value: "{{ line.value }}"
    - config: /etc/sysctl.conf
{% endfor %}

system_init_k8s_sysctl:
  file.managed:
    - name: /etc/sysctl.d/k8s.conf
    - source: salt://system-init/files/k8s-sysctl.conf
    - user: root
    - group: root
    - mode: 644

system_init_k8s_sysctl_cmd:
  cmd.wait:
    - name: sysctl --system
    - shell: /bin/bash
    - watch:
      - file: system_init_k8s_sysctl