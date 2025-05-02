#!/bin/bash
set -e

echo "Running nodetool status..."

OUTPUT=$(${CASSANDRA_BIN}/nodetool status)

echo "$OUTPUT"

# Need to check if "UN" is present (Up/Normal)
if echo "$OUTPUT" | grep -q 'UN'; then
    echo "Nodetool status is healthy: Node is Up and Normal."
else
    echo "Nodetool status check failed!"
    exit 1
fi
