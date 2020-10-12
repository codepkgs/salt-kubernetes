system_init_pip:
  file.managed:
    - name: /etc/pip.conf
    - source: salt://system-init/files/pip.conf
    - user: root
    - group: root
    - mode: 0644

system_init_pip_croniter:
  pip.installed:
    - name: croniter
    - require:
      - pkg: system_init_packages