#!/bin/bash

set -e

CASSANDRA_LOG_DIR="${CASSANDRA_LOG_DIR}" "${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    ${CASSANDRA_BIN}/${bin_script} "${@}"
