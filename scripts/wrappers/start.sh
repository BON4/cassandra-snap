#!/usr/bin/env bash

set -eu

source "${OPS_ROOT}"/helpers/snap-interfaces.sh

function start_cassandra () {
    exit_if_missing_perm "log-observe"
    exit_if_missing_perm "mount-observe"
    exit_if_missing_perm "sys-fs-cgroup-service"
    exit_if_missing_perm "system-observe"

    warn_if_missing_perm "process-control"

    # start
    "${SNAP}"/usr/bin/setpriv \
        --clear-groups \
        --reuid snap_daemon \
        --regid snap_daemon -- \
        "${CASSANDRA_BIN}"/cassandra
}


start_cassandra
