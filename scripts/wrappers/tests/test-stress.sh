#!/bin/bash
set -e

echo "Running stress tests..."

NUM_OPS=100000
THREADS=16
CL="ONE"

if ! command -v ${CASSANDRA_TOOLS_BIN}/cassandra-stress; then
    echo "[FAIED] cassandra-stress not instaled"
    exit 1
fi

echo "▶ Starting WRITE test..."
if ! ${CASSANDRA_TOOLS_BIN}/cassandra-stress write n=$NUM_OPS cl=$CL -rate threads=$THREADS; then
    echo "[FAIED] WRITE тест завершился с ошибкой"
    exit 1
fi
echo "[SUCESS] WRITE test"

echo "▶ Starting READ test..."
if ! ${CASSANDRA_TOOLS_BIN}/cassandra-stress read n=$NUM_OPS cl=$CL -rate threads=$THREADS; then
    echo "[FAIED] READ test"
    exit 1
fi
echo "[SUCESS] READ test"
