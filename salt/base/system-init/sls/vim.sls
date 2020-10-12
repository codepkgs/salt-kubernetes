{% if grains['os_family'].lower() == 'redhat' %}
system_init_vim_package:
  pkg.installed:
    - pkgs:
      - vim-enhanced
      - vim-common

system_init_vimrc:
  file.managed:
    - name: /root/.vimrc
    - source: salt://system-init/files/vimrc
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: system_init_vim_package
{% endif %}
