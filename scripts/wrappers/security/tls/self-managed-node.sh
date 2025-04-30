#!/usr/bin/env bash

set -eu

usage() {
cat << EOF
Usage: self-managed-node.sh --name <node-name> --root-password <password> --node-password <password> --target-dir <path>
Generates node certificate and keystore/truststore for Cassandra TLS.
  --name                Name of the node
  --node-password       Password for node keystore
  --root-password       Password for root key
  --node-subject        Subject for node cert (optional)
  --target-dir          Where certs and stores will be written
  --help                Show help
EOF
}

# Arguments
NODE_NAME=""
NODE_PASS=""
ROOT_PASS=""
NODE_SUBJ="/CN=Cassandra Node"
TARGET_DIR=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name) NODE_NAME="$2"; shift ;;
            --node-password) NODE_PASS="$2"; shift ;;
            --root-password) ROOT_PASS="$2"; shift ;;
            --node-subject) NODE_SUBJ="$2"; shift ;;
            --target-dir) TARGET_DIR="$2"; shift ;;
            --help) usage; exit 0 ;;
            *) echo "Unknown argument: $1"; usage; exit 1 ;;
        esac
        shift
    done

    if [[ -z $NODE_NAME || -z $NODE_PASS || -z $ROOT_PASS || -z $TARGET_DIR ]]; then
        echo "Missing required arguments"
        usage
        exit 1
    fi
}

generate_node_cert() {
    openssl req -newkey rsa:2048 -nodes \
        -keyout "${TARGET_DIR}/node-${NODE_NAME}-key.pem" \
        -out "${TARGET_DIR}/node-${NODE_NAME}.csr" \
        -subj "${NODE_SUBJ}"

    openssl x509 -req -in "${TARGET_DIR}/node-${NODE_NAME}.csr" \
        -CA "${TARGET_DIR}/root-ca.pem" \
        -CAkey "${TARGET_DIR}/root-ca-key.pem" \
        -CAcreateserial \
        -passin pass:"${ROOT_PASS}" \
        -out "${TARGET_DIR}/node-${NODE_NAME}.pem" -days 365 -sha256
}

create_keystore_truststore() {
    local keystore="${TARGET_DIR}/keystore.jks"
    local truststore="${TARGET_DIR}/truststore.jks"

    openssl pkcs12 -export \
        -in "${TARGET_DIR}/node-${NODE_NAME}.pem" \
        -inkey "${TARGET_DIR}/node-${NODE_NAME}-key.pem" \
        -certfile "${TARGET_DIR}/root-ca.pem" \
        -out "${TARGET_DIR}/node.p12" \
        -passout pass:"${NODE_PASS}"

    keytool -importkeystore \
        -destkeystore "${keystore}" \
        -srckeystore "${TARGET_DIR}/node.p12" \
        -srcstoretype PKCS12 \
        -deststoretype JKS \
        -alias 1 \
        -deststorepass "${NODE_PASS}" \
        -srcstorepass "${NODE_PASS}" \
        -noprompt

    keytool -import -trustcacerts \
        -alias root-ca \
        -file "${TARGET_DIR}/root-ca.pem" \
        -keystore "${truststore}" \
        -storepass "${NODE_PASS}" \
        -noprompt
}

main() {
    parse_args "$@"
    generate_node_cert
    create_keystore_truststore
}

main "$@"
