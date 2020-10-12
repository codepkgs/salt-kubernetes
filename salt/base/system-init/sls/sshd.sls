system_init_sshd_usedns:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^UseDNS\\s+.*"
    - repl: "UseDNS no"
    - append_if_not_found: True

{% if pillar['ssh_password_auth'] is defined and not pillar['ssh_password_auth'] %}
system_init_sshd_passwordauth:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PasswordAuthentication\\s+.*"
    - repl: "PasswordAuthentication no"
    - append_if_not_found: True
{% endif %}

system_init_sshd_service:
  service.running:
    - name: sshd
    - enable: True
    - watch:
      - file: /etc/ssh/sshd_config
