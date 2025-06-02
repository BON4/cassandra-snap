#!/bin/bash
set -e

echo "Running stress tests..."

NUM_OPS=100000
THREADS=16
CL="ONE"

if ! command -v snap > /dev/null; then
    echo "[FAILED] snap command not found"
    exit 1
fi

if ! snap run cassandra.stress help > /dev/null 2>&1; then
    echo "[FAILED] cassandra-stress is not installed or not available via snap"
    exit 1
fi

echo "▶ Starting WRITE test..."
if ! snap run cassandra.stress write n=$NUM_OPS cl=$CL -rate threads=$THREADS; then
    echo "[FAILED] WRITE test failed"
    exit 1
fi
echo "[SUCCESS] WRITE test completed"

echo "▶ Starting READ test..."
if ! snap run cassandra.stress read n=$NUM_OPS cl=$CL -rate threads=$THREADS; then
    echo "[FAILED] READ test failed"
    exit 1
fi
echo "[SUCCESS] READ test completed"
