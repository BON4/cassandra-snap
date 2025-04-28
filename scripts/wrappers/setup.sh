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
--help                                Shows help menu
EOF
}


# Args
cluster_name=""
node_host=""
seed_hosts=""
endpoint_snitch=""

# Args handling
function parse_args() {
    local LONG_OPTS_LIST=(
        "cluster-name"
        "node-host"
        "seed-hosts"
        "endpoint-snitch"
        "help"
    )
    # shellcheck disable=SC2155
    local opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(readlink -f "${BASH_SOURCE}")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --cluster-name) shift
                cluster_name=$1
                ;;
            --node-host) shift
                node_host=$1
                ;;
            --seed-hosts) shift
                seed_hosts=$1
                ;;
            --endpoint-snitch) shift
                endpoint-snitch=$1
                ;;
            --help) usage
                exit
                ;;
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

    if [ -z "${endpoint-snitch}" ]; then
        tls_for_rest="SimpleSnitch"
    fi
}


function validate_args () {
    err_message=""

    #TODO

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


parse_args "$@"
set_defaults
validate_args


cassandra_yaml="${CASSANDRA_CONF}/cassandra.yaml"
set_yaml_prop "${cassandra_yaml}" "cluster_name" "${cluster_name}"
set_yaml_prop "${cassandra_yaml}" "listen_address" "${node_host}"
set_yaml_prop "${cassandra_yaml}" "seed_provider/[0]/parameters/[0]/seeds" "${seed_hosts}"
set_yaml_prop "${cassandra_yaml}" "endpoint_snitch" "${endpoint-snitch}"
