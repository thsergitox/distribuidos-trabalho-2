#!/bin/bash

# Script para monitorear mensajes en tiempo real

if [ -z "$1" ]; then
    echo "Usage: ./watch-messages.sh <node-number>"
    echo "Example: ./watch-messages.sh 1"
    exit 1
fi

NODE=$1

case $NODE in
    1)
        IP="34.55.87.209"
        NAME="Iowa"
        ;;
    2)
        IP="34.95.212.100"
        NAME="São Paulo"
        ;;
    3)
        IP="35.201.29.184"
        NAME="Sydney"
        ;;
    *)
        echo "Invalid node number. Use 1, 2, or 3"
        exit 1
        ;;
esac

echo "Monitoring messages on Node $NODE ($NAME) - http://$IP/messages"
echo "Press Ctrl+C to stop"
echo "========================================"

watch -n 2 "curl -s http://$IP/messages | jq '.[] | {id, lamport_timestamp, node_id, content}'"
