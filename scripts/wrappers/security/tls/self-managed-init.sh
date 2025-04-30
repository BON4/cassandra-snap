#!/usr/bin/env bash

set -eu

usage() {
cat << EOF
Usage: self-managed-init.sh --root-password <password> --admin-password <password> --target-dir <path>
Generates root and admin certificates.
  --root-password       Password for root private key
  --admin-password      Password for admin private key
  --root-subject        Subject for root cert (optional)
  --admin-subject       Subject for admin cert (optional)
  --target-dir          Where to save generated certs
  --help                Show this message
EOF
}

# Arguments
ROOT_PASS=""
ADMIN_PASS=""
ROOT_SUBJ="/CN=Root Cassandra CA"
ADMIN_SUBJ="/CN=Admin Cassandra Client"
TARGET_DIR=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --root-password) ROOT_PASS="$2"; shift ;;
            --admin-password) ADMIN_PASS="$2"; shift ;;
            --root-subject) ROOT_SUBJ="$2"; shift ;;
            --admin-subject) ADMIN_SUBJ="$2"; shift ;;
            --target-dir) TARGET_DIR="$2"; shift ;;
            --help) usage; exit 0 ;;
            *) echo "Unknown argument: $1"; usage; exit 1 ;;
        esac
        shift
    done

    if [[ -z $ROOT_PASS || -z $ADMIN_PASS || -z $TARGET_DIR ]]; then
        echo "Missing required arguments."
        usage
        exit 1
    fi
}

generate_root_cert() {
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
        -keyout "${TARGET_DIR}/root-ca-key.pem" \
        -out "${TARGET_DIR}/root-ca.pem" \
        -passout pass:"${ROOT_PASS}" \
        -subj "${ROOT_SUBJ}" \
        -nodes
}

generate_admin_cert() {
    openssl req -newkey rsa:2048 -nodes \
        -keyout "${TARGET_DIR}/admin-key.pem" \
        -out "${TARGET_DIR}/admin.csr" \
        -subj "${ADMIN_SUBJ}"

    openssl x509 -req -in "${TARGET_DIR}/admin.csr" \
        -CA "${TARGET_DIR}/root-ca.pem" \
        -CAkey "${TARGET_DIR}/root-ca-key.pem" \
        -CAcreateserial \
        -passin pass:"${ROOT_PASS}" \
        -out "${TARGET_DIR}/admin.pem" -days 365 -sha256
}

main() {
    parse_args "$@"
    mkdir -p "${TARGET_DIR}"
    generate_root_cert
    generate_admin_cert
}

main "$@"
