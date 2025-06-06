#!/usr/bin/env bash

set -eu

source "${SNAP_CURRENT}"/opt/shared/bin/snap-interfaces.sh

# Args
set_sysctl_props=""


# Args handling
function parse_args () {
    # set_sysctl_props boolean - from the charm, this should be set to "yes".
    set_sysctl_props="$(snapctl get set-sysctl-props)"
}

function set_defaults () {
    if [ -z "${set_sysctl_props}" ] || [ "${set_sysctl_props}" != "yes" ]; then
        set_sysctl_props="no"
    fi
}

# See: https://docs.datastax.com/en/cassandra-oss/3.0/cassandra/install/installRecommendSettings.html#Setuserresourcelimits
function set_ulimits () {
    exit_if_missing_perm "sys-fs-cgroup-service"

    echo "Setting Cassandra ulimits..."

    # 1. Set max open file descriptors (nofile)
    current_nofile="$(ulimit -n)"
    if [ "${current_nofile}" != "unlimited" ] && [ "${current_nofile}" -lt 100000 ]; then
        ulimit -n 100000
    fi

    # 2. Set max number of processes (nproc)
    current_nproc="$(ulimit -u)"
    if [ "${current_nproc}" != "unlimited" ] && [ "${current_nproc}" -lt 32768 ]; then
        ulimit -u 32768
    fi

    # 3. Set max locked-in memory (memlock)
    current_memlock="$(ulimit -l)"
    if [ "${current_memlock}" != "unlimited" ]; then
        ulimit -l unlimited
    fi

    # 4. Set max address space (as)
    current_as="$(ulimit -v)"
    if [ "${current_as}" != "unlimited" ]; then
        ulimit -v unlimited
    fi
}

function set_proc_conf () {
    # 1. Allow the cassandra user to Disable all swap files:
    # swapon -a -- default in local machine
    "${SNAP}"/sbin/sysctl -w vm.swappiness=0

    # 2. Ensuring sufficient virtual memory: https://docs.datastax.com/en/cassandra-oss/3.0/cassandra/install/installRecommendSettings.html
    # sysctl -w vm.max_map_count=65530 -- default in local machine
    "${SNAP}"/sbin/sysctl -w vm.max_map_count=1048575
}

parse_args
set_defaults

set_ulimits

if [ "${set_sysctl_props}" == "yes" ]; then
    set_proc_conf
fi
