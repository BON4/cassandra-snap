#!/usr/bin/env bash

set -eu

source "${OPS_ROOT}"/helpers/snap-logger.sh "setup"
source "${OPS_ROOT}"/helpers/set-conf.sh
source "${OPS_ROOT}"/helpers/io.sh

usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--cluster-name            (Required)  Name of the cluster
--node-host               (Required)  IP address used to bind the node, default: localhost
--seed-hosts              (Required)  Private IP of all the cluster-manager eligible nodes, wihtout ports specified default: ["127.0.0.1:7000"]
--endpoint-snitch         (Optional)  Sets the snitch type that Cassandra uses to determine node topology (e.g., SimpleSnitch, GossipingPropertyFileSnitch). Default is [SimpleSnitch].
--tls-self-managed        (Optional)  Enable self-managed TLS
--tls-init-setup          (Optional)  Run initial TLS root/admin cert creation
--tls-priv-key-root-pass  (Optional)  Root CA private key passphrase
--tls-priv-key-admin-pass (Optional)  Admin cert private key passphrase
--tls-priv-key-node-pass  (Optional)  Node keystore/truststore passphrase
--tls-root-subject        (Optional)  Root cert X.509 subject
--tls-admin-subject       (Optional)  Admin cert X.509 subject
--tls-node-subject        (Optional)  Node cert X.509 subject
--help                                Shows help menu
EOF
}

TLS_DIR="${OPS_ROOT}/security/tls"

# Args
cluster_name=""
node_host=""
seed_hosts=""
endpoint_snitch=""
tls_self_managed=""
tls_init_setup=""
tls_priv_key_root_pass=""
tls_priv_key_admin_pass=""
tls_priv_key_node_pass=""
tls_root_subject=""
tls_admin_subject=""
tls_node_subject=""

# Args handling
function parse_args() {
    local LONG_OPTS_LIST=(
        "cluster-name"
        "node-host"
        "seed-hosts"
        "endpoint-snitch"
        "tls-self-managed"
        "tls-init-setup"
        "tls-priv-key-root-pass"
        "tls-priv-key-admin-pass"
        "tls-priv-key-node-pass"
        "tls-root-subject"
        "tls-admin-subject"
        "tls-node-subject"
        "help"
    )
    local opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(readlink -f "${BASH_SOURCE}")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --cluster-name) shift; cluster_name=$1 ;;
            --node-host) shift; node_host=$1 ;;
            --seed-hosts) shift; seed_hosts=$1 ;;
            --endpoint-snitch) shift; endpoint_snitch=$1 ;;
            --tls-self-managed) shift; tls_self_managed=$1 ;;
            --tls-init-setup) shift; tls_init_setup=$1 ;;
            --tls-priv-key-root-pass) shift; tls_priv_key_root_pass=$1 ;;
            --tls-priv-key-admin-pass) shift; tls_priv_key_admin_pass=$1 ;;
            --tls-priv-key-node-pass) shift; tls_priv_key_node_pass=$1 ;;
            --tls-root-subject) shift; tls_root_subject=$1 ;;
            --tls-admin-subject) shift; tls_admin_subject=$1 ;;
            --tls-node-subject) shift; tls_node_subject=$1 ;;
            --help) usage; exit ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${cluster_name}" ]; then
        cluster_name="cassandra-cluster"
    fi

    if [ -z "${node_host}" ]; then
        node_host="localhost"
    fi

    if [ -z "${seed_hosts}" ]; then
        seed_hosts="[ \"127.0.0.1:7000\" ]"
    fi

    if [ -z "${endpoint_snitch}" ]; then
        endpoint_snitch="SimpleSnitch"
    fi
}

function validate_args () {
    err_message=""
    # TODO: Add validation
    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}

function setup_tls () {
    if [ "${tls_self_managed}" == "yes" ]; then
        if [ "${tls_init_setup}" == "yes" ]; then
            source "${TLS_DIR}/self-managed-init.sh" \
                --root-password "${tls_priv_key_root_pass}" \
                --admin-password "${tls_priv_key_admin_pass}" \
                --root-subject "${tls_root_subject}" \
                --admin-subject "${tls_admin_subject}" \
                --target-dir "${CASSANDRA_PATH_CERTS}"

            for key in root-ca root-ca-key admin admin-key; do
                set_access_restrictions "${TLS_DIR}/${key}.pem" 664
            done
        fi

        source "${TLS_DIR}/self-managed-node.sh" \
            --name "${node_host}" \
            --root-password "${tls_priv_key_root_pass}" \
            --node-password "${tls_priv_key_node_pass}" \
            --node-subject "${tls_node_subject}" \
            --target-dir "${CASSANDRA_PATH_CERTS}"

        for key in node-${node_host} node-${node_host}-key keystore.jks truststore.jks; do
            set_access_restrictions "${TLS_DIR}/${key}" 664
        done

        # Apply Cassandra TLS config
        cassandra_yaml="${CASSANDRA_CONF}/cassandra.yaml"
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.enabled" true
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.optional" false
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.require_client_auth" true
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.keystore" "${TLS_DIR}/keystore.jks"
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.keystore_password" "${tls_priv_key_node_pass}"
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.truststore" "${TLS_DIR}/truststore.jks"
        set_yaml_prop "${cassandra_yaml}" "client_encryption_options.truststore_password" "${tls_priv_key_node_pass}"
    fi
}

parse_args "$@"
set_defaults
validate_args
setup_tls

cassandra_yaml="${CASSANDRA_CONF}/cassandra.yaml"
set_yaml_prop "${cassandra_yaml}" "cluster_name" "${cluster_name}"
set_yaml_prop "${cassandra_yaml}" "listen_address" "${node_host}"
set_yaml_prop "${cassandra_yaml}" "seed_provider/[0]/parameters/[0]/seeds" "${seed_hosts}"
set_yaml_prop "${cassandra_yaml}" "endpoint_snitch" "${endpoint_snitch}"
