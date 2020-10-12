system_init_selinux:
  file.replace:
    - name: /etc/sysconfig/selinux
    - pattern: "^SELINUX=(.*)"
    - repl: "SELINUX=disabled"
    - append_if_not_found: True