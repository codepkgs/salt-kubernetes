#!/bin/bash

clean() {
    rm -rf certs/* &> /dev/null
    rm -rf etcd.sls ../pillar/base/etcd/sls/etcd.sls &> /dev/null
    rm -rf files/ca-csr.json &> /dev/null
    rm -rf files/etcd-csr.json &> /dev/null
}

init() {
    python csr.py
    ca
    etcd
    python etcd_pillar.py
    mv etcd.sls ../pillar/base/etcd/sls/ &> /dev/null
}

ca() {
    local cert_filename='certs/ca.pem'
    local cert_csr='ca.csr'
    local csr_json='ca-csr.json'

    if [ "$force" == "1" ]; then
        cfssl gencert -initca ./files/$csr_json | cfssljson -bare ./certs/ca
        rm -rf ./certs/$cert_csr &> /dev/null
    elif [ ! -f "$cert_filename" ]; then
        cfssl gencert -initca ./files/$csr_json | cfssljson -bare ./certs/ca
        rm -rf ./certs/$cert_csr &> /dev/null
    else
        echo "warning: ca cert is exist now, if you want to generate, please use --force"
    fi
}

etcd() {
    local cert_filename='certs/etcd.pem'
    local cert_csr='etcd.csr'
    local csr_json='etcd-csr.json'

    if [ ! -f "./certs/ca.pem" -o ! -f "./certs/ca-key.pem" ]; then
        ca
    fi

    if [ "$force" == "1" ]; then
        cfssl gencert -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/$csr_json | cfssljson -bare ./certs/etcd
        rm -rf ./certs/$cert_csr &> /dev/null
    elif [ ! -f "$cert_filename" ]; then
        cfssl gencert -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/$csr_json | cfssljson -bare ./certs/etcd
        rm -rf ./certs/$cert_csr &> /dev/null
    else
        echo "warning: etcd cert is exist now, if you want to generate, please use --force"
    fi
}

help() {
    echo "before use this script, please modify json file in files directory"
    echo "usage: $0 [--force] ca|etcd|pc|clean"
    exit 0
}

if [ "$#" -eq 1 ]; then
    ops="$1"
elif [ "$#" -eq 2 ]; then
    if [ "$1" == '--force' ]; then
        force=1
    else
        force=0
    fi
    ops=$2
else
    help
fi

case $ops in
    init)
        init
        ;;
    ca)
        ca
        ;;
    etcd)
        etcd
        ;;
    clean)
        clean
        ;;
    *)
        help
esac
