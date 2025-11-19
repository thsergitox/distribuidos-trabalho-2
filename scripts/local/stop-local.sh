#!/bin/bash

# Script para detener el cluster local

echo "Stopping local distributed cluster..."

docker rm -f node1 node2 node3 2>/dev/null || true
docker network rm distributed-net 2>/dev/null || true

echo "✓ Cluster stopped and cleaned up"
