#!/bin/bash

# ============================================================================
# Script para re-deployar contenedores con configuración correcta
# ============================================================================
#
# Este script:
# 1. Rebuild y push imagen Docker con el fix de OTHER_SERVERS
# 2. Para y elimina contenedores viejos en las VMs
# 3. Inicia nuevos contenedores con las IPs públicas correctas
#
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

gcloud config set project $GCP_PROJECT_ID

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Redeploying Containers with Fix${NC}"
echo -e "${GREEN}========================================${NC}"

IMAGE_NAME="gcr.io/$GCP_PROJECT_ID/distributed-log:latest"

# ============================================================================
# PASO 1: Rebuild y push imagen
# ============================================================================
echo -e "\n${YELLOW}Step 1/3: Rebuilding Docker image...${NC}"
docker build -t $IMAGE_NAME .

echo -e "\n${YELLOW}Pushing image to GCR...${NC}"
docker push $IMAGE_NAME

# ============================================================================
# PASO 2: Obtener IPs de las VMs
# ============================================================================
echo -e "\n${YELLOW}Step 2/3: Getting VM IPs...${NC}"

declare -A REGIONS=(
    ["log-node-1"]="us-central1-a"
    ["log-node-2"]="southamerica-east1-a"
    ["log-node-3"]="australia-southeast1-a"
)

NODE_IDS=(8001 8002 8003)
VM_NAMES=(log-node-1 log-node-2 log-node-3)

declare -A IPS
for vm_name in "${VM_NAMES[@]}"; do
    zone="${REGIONS[$vm_name]}"
    ip=$(gcloud compute instances describe $vm_name \
        --zone=$zone \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    IPS[$vm_name]=$ip
    echo -e "  $vm_name: ${GREEN}$ip${NC}"
done

# Crear string de OTHER_SERVERS
IP1="${IPS[log-node-1]}"
IP2="${IPS[log-node-2]}"
IP3="${IPS[log-node-3]}"
OTHER_SERVERS="$IP1:80:8001,$IP2:80:8002,$IP3:80:8003"

echo -e "\n${BLUE}OTHER_SERVERS string:${NC}"
echo -e "  $OTHER_SERVERS"

# ============================================================================
# PASO 3: Re-deployar contenedores en cada VM
# ============================================================================
echo -e "\n${YELLOW}Step 3/3: Redeploying containers...${NC}"

for i in {0..2}; do
    vm_name="${VM_NAMES[$i]}"
    zone="${REGIONS[$vm_name]}"
    node_id="${NODE_IDS[$i]}"

    echo -e "\n${BLUE}Redeploying on $vm_name...${NC}"

    gcloud compute ssh $vm_name --zone=$zone --command="
        echo '=== Stopping old container ==='
        docker stop distributed-log 2>/dev/null || true
        docker rm distributed-log 2>/dev/null || true

        echo '=== Pulling latest image ==='
        docker pull $IMAGE_NAME

        echo '=== Starting new container ==='
        docker run -d \
          --name distributed-log \
          --restart unless-stopped \
          -p 80:80 \
          -e NODE_ID=$node_id \
          -e OTHER_SERVERS='$OTHER_SERVERS' \
          $IMAGE_NAME

        echo '=== Container status ==='
        docker ps
        sleep 2
        docker logs distributed-log --tail 20
    "

    echo -e "${GREEN}✓ $vm_name redeployed${NC}"
done

# ============================================================================
# PASO 4: Verificar deployment
# ============================================================================
echo -e "\n${YELLOW}Waiting 15 seconds for containers to start...${NC}"
sleep 15

echo -e "\n${YELLOW}Verifying deployment...${NC}"

for vm_name in "${VM_NAMES[@]}"; do
    ip="${IPS[$vm_name]}"
    echo -e "\n${BLUE}Testing $vm_name ($ip)...${NC}"

    if curl -s -f "http://$ip/lamport_time" > /dev/null; then
        lamport=$(curl -s "http://$ip/lamport_time")
        leader=$(curl -s "http://$ip/leader")
        echo -e "  ${GREEN}✓ Responding${NC}"
        echo -e "  Lamport: $lamport"
        echo -e "  Leader: $leader"
    else
        echo -e "  ${RED}✗ Not responding${NC}"
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}REDEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}Test commands:${NC}"
echo -e "  curl -X POST 'http://$IP3/?message=Test_from_Sydney'"
echo -e "  curl http://$IP1/messages"
echo -e "  ./check-gcp-status.sh"
