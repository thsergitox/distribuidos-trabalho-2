#!/bin/bash

# Script para debug de un nodo específico

if [ -z "$1" ]; then
    echo "Usage: ./debug-node.sh <node-number>"
    echo "Example: ./debug-node.sh 1"
    exit 1
fi

NODE_NUM=$1
VM_NAME="log-node-$NODE_NUM"

declare -A ZONES=(
    ["1"]="us-central1-a"
    ["2"]="southamerica-east1-a"
    ["3"]="australia-southeast1-a"
)

ZONE="${ZONES[$NODE_NUM]}"

echo "========================================="
echo "Debugging $VM_NAME in zone $ZONE"
echo "========================================="

echo -e "\n=== Checking if VM is running ==="
gcloud compute instances describe $VM_NAME --zone=$ZONE --format='get(status)'

echo -e "\n=== Checking startup script logs ==="
gcloud compute ssh $VM_NAME --zone=$ZONE --command='sudo tail -100 /var/log/syslog | grep startup-script'

echo -e "\n=== Checking if Docker is installed ==="
gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker --version'

echo -e "\n=== Checking if container is running ==="
gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker ps -a'

echo -e "\n=== Checking container logs (if exists) ==="
gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker logs distributed-log 2>&1 | tail -50' || true

echo -e "\n=== Checking if image was pulled ==="
gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker images | grep distributed-log'
