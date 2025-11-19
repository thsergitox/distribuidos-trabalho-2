#!/bin/bash

# ============================================================================
# Script para verificar el estado del deployment en GCP
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GCP_PROJECT_ID not set!${NC}"
    exit 1
fi

gcloud config set project $GCP_PROJECT_ID > /dev/null 2>&1

declare -A REGIONS=(
    ["log-node-1"]="us-central1-a"
    ["log-node-2"]="southamerica-east1-a"
    ["log-node-3"]="australia-southeast1-a"
)

NODE_IDS=(8001 8002 8003)
VM_NAMES=(log-node-1 log-node-2 log-node-3)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GCP Deployment Status Check${NC}"
echo -e "${GREEN}========================================${NC}"

# Obtener IPs
declare -A IPS
for vm_name in "${VM_NAMES[@]}"; do
    zone="${REGIONS[$vm_name]}"
    ip=$(gcloud compute instances describe $vm_name \
        --zone=$zone \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null || echo "N/A")
    IPS[$vm_name]=$ip
done

echo -e "\n${BLUE}VMs Status:${NC}"
for i in {0..2}; do
    vm_name="${VM_NAMES[$i]}"
    ip="${IPS[$vm_name]}"
    node_id="${NODE_IDS[$i]}"
    zone="${REGIONS[$vm_name]}"

    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$vm_name (NODE_ID=$node_id)${NC}"
    echo -e "${YELLOW}IP: $ip${NC}"
    echo -e "${YELLOW}Zone: $zone${NC}"

    # Verificar si responde HTTP
    if curl -s -f "http://$ip/lamport_time" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ HTTP responding${NC}"

        # Obtener info del nodo
        lamport=$(curl -s "http://$ip/lamport_time" 2>/dev/null || echo "N/A")
        leader=$(curl -s "http://$ip/leader" 2>/dev/null || echo "N/A")
        msg_count=$(curl -s "http://$ip/messages" 2>/dev/null | grep -c '"id"' || echo "0")

        echo -e "  Lamport Time: $lamport"
        echo -e "  Leader ID: $leader"
        echo -e "  Messages: $msg_count"
    else
        echo -e "${RED}✗ Not responding (container may still be starting)${NC}"

        # Intentar ver logs si es posible
        echo -e "${BLUE}Checking startup progress...${NC}"
        startup_log=$(gcloud compute ssh $vm_name --zone=$zone \
            --command='tail -20 /var/log/syslog 2>/dev/null | grep "startup-script" | tail -5' \
            2>/dev/null || echo "")

        if [ ! -z "$startup_log" ]; then
            echo -e "${BLUE}Recent startup logs:${NC}"
            echo "$startup_log"
        fi
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Testing Commands:${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${BLUE}Send message to leader:${NC}"
echo -e "  curl -X POST 'http://${IPS[log-node-3]}/?message=Hello_from_Sydney'"
echo -e "\n${BLUE}Check messages on any node:${NC}"
echo -e "  curl http://${IPS[log-node-1]}/messages"
echo -e "\n${BLUE}View container logs:${NC}"
echo -e "  gcloud compute ssh log-node-1 --zone=us-central1-a --command='docker logs distributed-log'"
