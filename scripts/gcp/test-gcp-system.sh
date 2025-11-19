#!/bin/bash

# ============================================================================
# Script para probar el sistema distribuido en GCP
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GCP_PROJECT_ID not set!${NC}"
    exit 1
fi

gcloud config set project $GCP_PROJECT_ID > /dev/null 2>&1

# Obtener IPs
declare -A REGIONS=(
    ["log-node-1"]="us-central1-a"
    ["log-node-2"]="southamerica-east1-a"
    ["log-node-3"]="australia-southeast1-a"
)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Getting VM IPs...${NC}"
echo -e "${GREEN}========================================${NC}"

IP1=$(gcloud compute instances describe log-node-1 --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP2=$(gcloud compute instances describe log-node-2 --zone=southamerica-east1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP3=$(gcloud compute instances describe log-node-3 --zone=australia-southeast1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo -e "${BLUE}Node 1 (Iowa):${NC}       http://$IP1"
echo -e "${BLUE}Node 2 (São Paulo):${NC} http://$IP2"
echo -e "${BLUE}Node 3 (Sydney):${NC}    http://$IP3"

# Test 1: Verificar que todos los nodos están vivos
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TEST 1: Health Check${NC}"
echo -e "${GREEN}========================================${NC}"

for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    echo -e "\n${YELLOW}Node $i:${NC}"

    lamport=$(curl -s "http://$ip/lamport_time" || echo "ERROR")
    leader=$(curl -s "http://$ip/leader" || echo "ERROR")

    echo "  Lamport: $lamport"
    echo "  Leader:  $leader"
done

# Test 2: Enviar mensajes desde diferentes nodos
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TEST 2: Sending Messages${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Sending message to Node 1 (Iowa)...${NC}"
response1=$(curl -s -X POST "http://$IP1/?message=Hello_from_Iowa")
echo "Response: $response1"

echo -e "\n${YELLOW}Sending message to Node 2 (São Paulo)...${NC}"
response2=$(curl -s -X POST "http://$IP2/?message=Oi_from_Brazil")
echo "Response: $response2"

echo -e "\n${YELLOW}Sending message to Node 3 (Sydney - LEADER)...${NC}"
response3=$(curl -s -X POST "http://$IP3/?message=Gday_from_Australia")
echo "Response: $response3"

# Esperar a que se replique
echo -e "\n${CYAN}Waiting 3 seconds for replication...${NC}"
sleep 3

# Test 3: Verificar replicación
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TEST 3: Checking Replication${NC}"
echo -e "${GREEN}========================================${NC}"

for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    echo -e "\n${YELLOW}Messages on Node $i:${NC}"

    messages=$(curl -s "http://$ip/messages")

    # Formatear con jq si está disponible
    if command -v jq &> /dev/null; then
        echo "$messages" | jq '.'
    else
        echo "$messages"
    fi

    # Contar mensajes
    count=$(echo "$messages" | grep -c '"id"' || echo "0")
    echo -e "${CYAN}Total messages: $count${NC}"
done

# Test 4: Verificar Lamport timestamps
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TEST 4: Lamport Clock Verification${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Current Lamport time on each node:${NC}"
for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    lamport=$(curl -s "http://$ip/lamport_time")
    echo "  Node $i: $lamport"
done

# Test 5: Simular concurrencia
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TEST 5: Concurrent Writes (10 messages)${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Sending 10 concurrent messages...${NC}"

for i in {1..10}; do
    curl -s -X POST "http://$IP1/?message=Concurrent_msg_$i" > /dev/null &
done

wait

echo -e "${GREEN}✓ All concurrent messages sent${NC}"

echo -e "\n${CYAN}Waiting 5 seconds for replication...${NC}"
sleep 5

# Verificar que todos tienen los mismos mensajes
echo -e "\n${YELLOW}Verifying all nodes have the same messages...${NC}"

for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    count=$(curl -s "http://$ip/messages" | grep -c '"id"' || echo "0")
    echo "  Node $i: $count messages"
done

# Test 6: Simular fallo del líder (opcional - para el video)
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TEST 6: Leader Failure Simulation (OPTIONAL)${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}To simulate leader failure, run:${NC}"
echo -e "  gcloud compute ssh log-node-3 --zone=australia-southeast1-a --command='docker stop distributed-log'"
echo -e "\n${YELLOW}Then wait 10-15 seconds and check who becomes the new leader:${NC}"
echo -e "  curl http://$IP1/leader"
echo -e "  curl http://$IP2/leader"
echo -e "\n${YELLOW}To restore the leader:${NC}"
echo -e "  gcloud compute ssh log-node-3 --zone=australia-southeast1-a --command='docker start distributed-log'"

# Resumen final
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}SUMMARY${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}Quick access URLs:${NC}"
echo -e "  Node 1 messages: ${CYAN}http://$IP1/messages${NC}"
echo -e "  Node 2 messages: ${CYAN}http://$IP2/messages${NC}"
echo -e "  Node 3 messages: ${CYAN}http://$IP3/messages${NC}"

echo -e "\n${BLUE}Send message:${NC}"
echo -e "  curl -X POST 'http://$IP3/?message=Your_Message_Here'"

echo -e "\n${BLUE}View in browser:${NC}"
echo -e "  Node 1: ${CYAN}http://$IP1/docs${NC}"
echo -e "  Node 2: ${CYAN}http://$IP2/docs${NC}"
echo -e "  Node 3: ${CYAN}http://$IP3/docs${NC}"

echo -e "\n${GREEN}Testing complete! 🎉${NC}"
