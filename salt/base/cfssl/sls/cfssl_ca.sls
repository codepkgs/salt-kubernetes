cfssl_cert_ca:
  cmd.run:
    - name: cfssl gencert -initca configs/ca-csr.json | cfssljson -bare certs/ca
    - cwd: /etc/cfssl
    - shell: /bin/bash
    - unless: test -f /etc/cfssl/certs/ca.pem
    - require:
      - file: cfssl_default_config_ca-csr.json