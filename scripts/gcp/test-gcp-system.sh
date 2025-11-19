#!/bin/bash

# ============================================================================
# Script para testar o sistema distribuído no GCP
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}ERRO: GCP_PROJECT_ID não configurado!${NC}"
    exit 1
fi

gcloud config set project $GCP_PROJECT_ID > /dev/null 2>&1

# Obter IPs
declare -A REGIONS=(
    ["log-node-1"]="us-central1-a"
    ["log-node-2"]="southamerica-east1-a"
    ["log-node-3"]="australia-southeast1-a"
)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Obtendo IPs das VMs...${NC}"
echo -e "${GREEN}========================================${NC}"

IP1=$(gcloud compute instances describe log-node-1 --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP2=$(gcloud compute instances describe log-node-2 --zone=southamerica-east1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP3=$(gcloud compute instances describe log-node-3 --zone=australia-southeast1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo -e "${BLUE}Node 1 (Iowa):${NC}       http://$IP1"
echo -e "${BLUE}Node 2 (São Paulo):${NC} http://$IP2"
echo -e "${BLUE}Node 3 (Sydney):${NC}    http://$IP3"

# Teste 1: Verificar que todos os nós estão vivos
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TESTE 1: Verificação de Saúde${NC}"
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

# Teste 2: Enviar mensagens de diferentes nós
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TESTE 2: Enviando Mensagens${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Enviando mensagem para Node 1 (Iowa)...${NC}"
response1=$(curl -s -X POST "http://$IP1/?message=Hello_from_Iowa")
echo "Response: $response1"

echo -e "\n${YELLOW}Enviando mensagem para Node 2 (São Paulo)...${NC}"
response2=$(curl -s -X POST "http://$IP2/?message=Oi_from_Brazil")
echo "Response: $response2"

echo -e "\n${YELLOW}Enviando mensagem para Node 3 (Sydney - LÍDER)...${NC}"
response3=$(curl -s -X POST "http://$IP3/?message=Gday_from_Australia")
echo "Response: $response3"

# Aguardar para que seja replicado
echo -e "\n${CYAN}Aguardando 3 segundos para replicação...${NC}"
sleep 3

# Teste 3: Verificar replicação
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TESTE 3: Verificando Replicação${NC}"
echo -e "${GREEN}========================================${NC}"

for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    echo -e "\n${YELLOW}Mensagens no Node $i:${NC}"

    messages=$(curl -s "http://$ip/messages")

    # Formatar com jq se disponível
    if command -v jq &> /dev/null; then
        echo "$messages" | jq '.'
    else
        echo "$messages"
    fi

    # Contar mensagens
    count=$(echo "$messages" | grep -c '"id"' || echo "0")
    echo -e "${CYAN}Total de mensagens: $count${NC}"
done

# Teste 4: Verificar timestamps Lamport
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TESTE 4: Verificação do Relógio de Lamport${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Tempo Lamport atual em cada nó:${NC}"
for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    lamport=$(curl -s "http://$ip/lamport_time")
    echo "  Node $i: $lamport"
done

# Teste 5: Simular concorrência
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TESTE 5: Escritas Concorrentes (10 mensagens)${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Enviando 10 mensagens concorrentes...${NC}"

for i in {1..10}; do
    curl -s -X POST "http://$IP1/?message=Concurrent_msg_$i" > /dev/null &
done

wait

echo -e "${GREEN}✓ Todas as mensagens concorrentes enviadas${NC}"

echo -e "\n${CYAN}Aguardando 5 segundos para replicação...${NC}"
sleep 5

# Verificar que todos têm as mesmas mensagens
echo -e "\n${YELLOW}Verificando que todos os nós têm as mesmas mensagens...${NC}"

for i in 1 2 3; do
    ip_var="IP$i"
    ip="${!ip_var}"
    count=$(curl -s "http://$ip/messages" | grep -c '"id"' || echo "0")
    echo "  Node $i: $count mensagens"
done

# Teste 6: Simular falha do líder (opcional - para o vídeo)
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}TESTE 6: Simulação de Falha do Líder (OPCIONAL)${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Para simular falha do líder, execute:${NC}"
echo -e "  gcloud compute ssh log-node-3 --zone=australia-southeast1-a --command='docker stop distributed-log'"
echo -e "\n${YELLOW}Depois aguarde 10-15 segundos e verifique quem se torna o novo líder:${NC}"
echo -e "  curl http://$IP1/leader"
echo -e "  curl http://$IP2/leader"
echo -e "\n${YELLOW}Para restaurar o líder:${NC}"
echo -e "  gcloud compute ssh log-node-3 --zone=australia-southeast1-a --command='docker start distributed-log'"

# Resumo final
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}RESUMO${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}URLs de acesso rápido:${NC}"
echo -e "  Mensagens Node 1: ${CYAN}http://$IP1/messages${NC}"
echo -e "  Mensagens Node 2: ${CYAN}http://$IP2/messages${NC}"
echo -e "  Mensagens Node 3: ${CYAN}http://$IP3/messages${NC}"

echo -e "\n${BLUE}Enviar mensagem:${NC}"
echo -e "  curl -X POST 'http://$IP3/?message=Sua_Mensagem_Aqui'"

echo -e "\n${BLUE}Ver no navegador:${NC}"
echo -e "  Node 1: ${CYAN}http://$IP1/docs${NC}"
echo -e "  Node 2: ${CYAN}http://$IP2/docs${NC}"
echo -e "  Node 3: ${CYAN}http://$IP3/docs${NC}"

echo -e "\n${GREEN}Testes completos! 🎉${NC}"
