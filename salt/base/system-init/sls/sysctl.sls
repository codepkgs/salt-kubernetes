{% for line in pillar['sysctl_configs'] %}
{{ line.key }}:
  sysctl.present:
    - value: "{{ line.value }}"
    - config: /etc/sysctl.conf
{% endfor %}
