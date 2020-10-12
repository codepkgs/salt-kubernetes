system_init_ulimits:
  file.append:
    - name: /etc/security/limits.conf
    - text:
    {% for line in pillar['ulimits_config'] %}
        - "{{ line }}"
    {% endfor %}