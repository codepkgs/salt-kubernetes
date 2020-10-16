ipvs_pkgs:
  pkg.installed:
    - pkgs:
      - ipvsadm
      - ipset
      - sysstat
      - libnetfilter_conntrack
      - libseccomp

ipvs_file:
  file.managed:
    - name: /etc/sysconfig/ipvsadm
    - user: root
    - group: root
    - mode: 644

ipvs_modules_config:
  file.managed:
    - name: /etc/modules-load.d/ipvs.conf
    - source: salt://k8s-worker/files/ipvs/ipvs_modules.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: ipvs_pkgs

ipvs_config:
  file.managed:
    - name: /etc/modprobe.d/ipvs.conf
    - source: salt://k8s-worker/files/ipvs/ipvs.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: ipvs_pkgs

ipvs_modules:
  kmod.present:
    - mods:
      - ip_vs
      - ip_vs_rr
      - ip_vs_wrr
      - ip_vs_lc
      - ip_vs_wlc
      - ip_vs_sh
      - nf_conntrack
      - br_netfilter

ipvs_service:
  service.enabled:
    - name: ipvsadm
