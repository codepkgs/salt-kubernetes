{% if grains['os_family'].lower() == 'redhat' %}
system_init_packages:
  pkg.installed:
    - pkgs:
      {% for package in pillar['install_packages'] %}
      - "{{ package }}"
      {% endfor %}
{% endif %}