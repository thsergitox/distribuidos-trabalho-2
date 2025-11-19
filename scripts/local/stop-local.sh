#!/bin/bash

# Script para parar o cluster local

echo "Parando cluster distribuído local..."

docker rm -f node1 node2 node3 2>/dev/null || true
docker network rm distributed-net 2>/dev/null || true

echo "✓ Cluster parado e limpo"
