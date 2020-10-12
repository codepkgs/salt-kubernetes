system_init_unmount_swap:
  cmd.run:
    - name: sed -i '/^[^#]*swap.*/s/^/#/' /etc/fstab
    - shell: /bin/bash
    - onlyif: grep '^[^#]*swap.*' /etc/fstab
