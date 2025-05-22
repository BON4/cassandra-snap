#!/usr/bin/env bash

set -eu

source "${CASSANDRA_ROOT}"/helpers/snap-logger.sh "setup"
source "${CASSANDRA_ROOT}"/helpers/set-conf.sh
source "${CASSANDRA_ROOT}"/helpers/io.sh

usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--cluster-name            (Optional)  Name of the cluster
--node-host               (Optional)  IP address used to bind the node, default: localhost
--seed-hosts              (Optional)  Private IP of all the cluster-manager eligible nodes separated by coma, wihtout ports specified default: "127.0.0.1:7000"
--endpoint-snitch         (Optional)  Sets the snitch type that Cassandra uses to determine node topology (e.g., SimpleSnitch, GossipingPropertyFileSnitch). Default is [SimpleSnitch].
--enable-managment-api    (Optional)  Enables cassandra managment REST api 
--help                                Shows help menu
EOF
}

# TODO: add enable-managment-api param validation

# Args
cluster_name=""
node_host=""
seed_hosts=""
endpoint_snitch=""
enable_mgmt_api="false"

# Args handling
function parse_args() {
    local LONG_OPTS="cluster-name:,node-host:,seed-hosts:,endpoint-snitch:,enable-managment-api,help"

    local opts
    opts=$(getopt \
      --longoptions "${LONG_OPTS}" \
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
            --enable-managment-api) enable_mgmt_api="true" ;;
            --help) usage; exit 0 ;;
            --) shift; break ;; # end of options
            *) echo "Unexpected option: $1"; usage; exit 1 ;;
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
        seed_hosts="127.0.0.1:7000"
    fi

    if [ -z "${endpoint_snitch}" ]; then
        endpoint_snitch="SimpleSnitch"
    fi
}

function validate_args () {
    local err_message=""

    if [[ "${enable_mgmt_api}" == "true" && ! -f "${MGMT_API_DIR}/datastax-mgmtapi-agent.jar" ]]; then
        err_message+="\nError: Management API requested, but ${MGMT_API_DIR}/datastax-mgmtapi-agent.jar is missing."
    fi

    if [ -n "${err_message}" ]; then
        echo -e "\nThe following errors occurred: \n${err_message}\nRefer to the help menu."
        exit 1
    fi
}

parse_args "$@"
set_defaults
validate_args

cassandra_yaml="${CASSANDRA_CONF}/cassandra.yaml"
set_yaml_prop "${cassandra_yaml}" "cluster_name" "${cluster_name}"
set_yaml_prop "${cassandra_yaml}" "listen_address" "${node_host}"
# TODO. seeds may be set incorectly if many is provided
set_yaml_prop "${cassandra_yaml}" "seed_provider/[0]/parameters/[0]/seeds" "${seed_hosts}"
set_yaml_prop "${cassandra_yaml}" "endpoint_snitch" "${endpoint_snitch}"

# Enable management API if requested
if [ "${enable_mgmt_api}" = "true" ]; then
    echo "\nEnabling Management API..."
    echo "JVM_OPTS=\"\$JVM_OPTS -javaagent:${MGMT_API_DIR}/datastax-mgmtapi-agent.jar\"" >> "${CASSANDRA_CONF}/cassandra-env.sh"
fi
