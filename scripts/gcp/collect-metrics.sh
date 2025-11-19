#!/bin/bash

# ============================================================================
# Script para coletar métricas completas do sistema distribuído
# Para o relatório IEEE
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# IPs dos nós (atualizar se mudarem)
NODE1_IP="34.55.87.209"      # Iowa
NODE2_IP="34.95.212.100"     # São Paulo
NODE3_IP="35.201.29.184"     # Sydney (Leader)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Coleta de Métricas - Sistema Distribuído${NC}"
echo -e "${GREEN}Trabalho 2 - MC714 Sistemas Distribuídos${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================================================
# TESTE 1: Latência HTTP entre regiões
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TESTE 1: Latência HTTP entre Regiões${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Medindo latência para Iowa (us-central1):${NC}"
for i in {1..5}; do
    time_ms=$( { time curl -s http://$NODE1_IP/lamport_time > /dev/null; } 2>&1 | grep real | awk '{print $2}')
    echo "  Tentativa $i: $time_ms"
done

echo -e "\n${CYAN}Medindo latência para São Paulo (southamerica-east1):${NC}"
for i in {1..5}; do
    time_ms=$( { time curl -s http://$NODE2_IP/lamport_time > /dev/null; } 2>&1 | grep real | awk '{print $2}')
    echo "  Tentativa $i: $time_ms"
done

echo -e "\n${CYAN}Medindo latência para Sydney (australia-southeast1):${NC}"
for i in {1..5}; do
    time_ms=$( { time curl -s http://$NODE3_IP/lamport_time > /dev/null; } 2>&1 | grep real | awk '{print $2}')
    echo "  Tentativa $i: $time_ms"
done

# ============================================================================
# TESTE 2: Throughput sob carga sustentada (50 mensagens)
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TESTE 2: Throughput - 50 Mensagens Concorrentes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Enviando 50 mensagens concorrentes para o líder (Sydney)...${NC}"
start_time=$(date +%s.%N)

for i in {1..50}; do
    curl -s -X POST "http://$NODE3_IP/?message=LoadTest_$i" > /dev/null &
done
wait

end_time=$(date +%s.%N)
duration=$(awk "BEGIN {printf \"%.3f\", $end_time - $start_time}")
throughput=$(awk "BEGIN {printf \"%.2f\", 50 / $duration}")

echo -e "${GREEN}✓ Mensagens enviadas${NC}"
echo -e "  Tempo total: ${duration}s"
echo -e "  Throughput: ${throughput} msg/s"

echo -e "\n${CYAN}Aguardando 5 segundos para replicação...${NC}"
sleep 5

# Verificar replicação
echo -e "\n${CYAN}Verificando replicação em todos os nós:${NC}"
node1_count=$(curl -s http://$NODE1_IP/messages | grep -c '"id"' || echo "0")
node2_count=$(curl -s http://$NODE2_IP/messages | grep -c '"id"' || echo "0")
node3_count=$(curl -s http://$NODE3_IP/messages | grep -c '"id"' || echo "0")

echo -e "  Node 1 (Iowa):      ${node1_count} mensagens"
echo -e "  Node 2 (São Paulo): ${node2_count} mensagens"
echo -e "  Node 3 (Sydney):    ${node3_count} mensagens"

if [ "$node1_count" == "$node2_count" ] && [ "$node2_count" == "$node3_count" ]; then
    echo -e "${GREEN}✓ Replicação consistente em todos os nós${NC}"
else
    echo -e "${RED}✗ Inconsistência detectada na replicação${NC}"
fi

# ============================================================================
# TESTE 3: Relógio de Lamport com escritores concorrentes
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TESTE 3: Relógio de Lamport - Escritores Concorrentes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Rodada 1: Enviando dos 3 nós simultaneamente...${NC}"
curl -s -X POST "http://$NODE1_IP/?message=Concurrent_Iowa_1" > /dev/null &
curl -s -X POST "http://$NODE2_IP/?message=Concurrent_Brazil_1" > /dev/null &
curl -s -X POST "http://$NODE3_IP/?message=Concurrent_Sydney_1" > /dev/null &
wait

sleep 3

echo -e "${CYAN}Rodada 2: Enviando outra rodada simultânea...${NC}"
curl -s -X POST "http://$NODE1_IP/?message=Concurrent_Iowa_2" > /dev/null &
curl -s -X POST "http://$NODE2_IP/?message=Concurrent_Brazil_2" > /dev/null &
curl -s -X POST "http://$NODE3_IP/?message=Concurrent_Sydney_2" > /dev/null &
wait

sleep 3

echo -e "${CYAN}Rodada 3: Enviando terceira rodada simultânea...${NC}"
curl -s -X POST "http://$NODE1_IP/?message=Concurrent_Iowa_3" > /dev/null &
curl -s -X POST "http://$NODE2_IP/?message=Concurrent_Brazil_3" > /dev/null &
curl -s -X POST "http://$NODE3_IP/?message=Concurrent_Sydney_3" > /dev/null &
wait

sleep 5

# Ver timestamps Lamport atuais
echo -e "\n${CYAN}Estado atual dos relógios de Lamport:${NC}"
lamport1=$(curl -s http://$NODE1_IP/lamport_time)
lamport2=$(curl -s http://$NODE2_IP/lamport_time)
lamport3=$(curl -s http://$NODE3_IP/lamport_time)

echo -e "  Node 1 (Iowa):      $lamport1"
echo -e "  Node 2 (São Paulo): $lamport2"
echo -e "  Node 3 (Sydney):    $lamport3"

# Ver últimas 10 mensagens com timestamps
echo -e "\n${CYAN}Últimas mensagens com Lamport timestamps (Node 1):${NC}"
curl -s http://$NODE1_IP/messages | grep -E '"(id|content|lamport_timestamp|node_id)"' | tail -30

# ============================================================================
# TESTE 4: Latência de replicação geográfica
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TESTE 4: Latência de Replicação Geográfica${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Enviando mensagem marcada com timestamp...${NC}"
unique_msg="ReplicationTest_$(date +%s)"
timestamp_send=$(date +%s.%N)

curl -s -X POST "http://$NODE3_IP/?message=$unique_msg" > /dev/null

echo -e "Mensagem enviada: $unique_msg"
echo -e "Timestamp envio: $timestamp_send"

# Verificar a cada 0.5s até que apareça em todos os nós
echo -e "\n${CYAN}Monitorando aparição em cada nó...${NC}"

for node_ip in $NODE1_IP $NODE2_IP $NODE3_IP; do
    echo -e "\nVerificando em $node_ip..."
    for i in {1..20}; do
        if curl -s "http://$node_ip/messages" | grep -q "$unique_msg"; then
            timestamp_recv=$(date +%s.%N)
            latency=$(awk "BEGIN {printf \"%.3f\", $timestamp_recv - $timestamp_send}")
            echo -e "  ${GREEN}✓ Mensagem replicada em ${latency}s${NC}"
            break
        fi
        sleep 0.5
    done
done

# ============================================================================
# TESTE 5: Throughput com diferentes cargas
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TESTE 5: Throughput com Diferentes Cargas${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for load in 10 25 50 100; do
    echo -e "\n${CYAN}Testando com $load mensagens...${NC}"

    start=$(date +%s.%N)
    for i in $(seq 1 $load); do
        curl -s -X POST "http://$NODE3_IP/?message=Load${load}_Msg$i" > /dev/null &
    done
    wait
    end=$(date +%s.%N)

    duration=$(awk "BEGIN {printf \"%.3f\", $end - $start}")
    tput=$(awk "BEGIN {printf \"%.2f\", $load / $duration}")

    echo -e "  Carga: $load mensagens"
    echo -e "  Tempo: ${duration}s"
    echo -e "  Throughput: ${tput} msg/s"

    sleep 3
done

# ============================================================================
# TESTE 6: Estado final do sistema
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TESTE 6: Estado Final do Sistema${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Informação de cada nó:${NC}"

for i in 1 2 3; do
    if [ $i -eq 1 ]; then
        ip=$NODE1_IP
        region="Iowa (us-central1-a)"
    elif [ $i -eq 2 ]; then
        ip=$NODE2_IP
        region="São Paulo (southamerica-east1-a)"
    else
        ip=$NODE3_IP
        region="Sydney (australia-southeast1-a)"
    fi

    echo -e "\n${BLUE}Node $i - $region${NC}"
    echo -e "  IP: $ip"

    lamport=$(curl -s http://$ip/lamport_time)
    leader=$(curl -s http://$ip/leader)
    msg_count=$(curl -s http://$ip/messages | grep -c '"id"' || echo "0")

    echo -e "  Lamport Time: $lamport"
    echo -e "  Leader ID: $leader"
    echo -e "  Total Messages: $msg_count"
done

# ============================================================================
# Resumo
# ============================================================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}MÉTRICAS COLETADAS COM SUCESSO${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}Dados obtidos:${NC}"
echo -e "  ✓ Latências HTTP entre regiões (5 amostras por região)"
echo -e "  ✓ Throughput com 50 mensagens concorrentes"
echo -e "  ✓ Convergência de relógios de Lamport"
echo -e "  ✓ Latência de replicação geográfica"
echo -e "  ✓ Throughput com cargas variáveis (10, 25, 50, 100 msg)"
echo -e "  ✓ Estado final do sistema distribuído"

echo -e "\n${BLUE}Regiões geográficas:${NC}"
echo -e "  • Iowa (us-central1-a)"
echo -e "  • São Paulo (southamerica-east1-a)"
echo -e "  • Sydney (australia-southeast1-a)"

echo -e "\n${BLUE}Distâncias aproximadas:${NC}"
echo -e "  • Iowa ↔ São Paulo: ~8.000 km"
echo -e "  • Iowa ↔ Sydney: ~13.000 km"
echo -e "  • São Paulo ↔ Sydney: ~15.000 km"
echo -e "  • Total: ~36.000 km de separação"

echo -e "\n${GREEN}Pronto para escrever o relatório IEEE! 📊${NC}"
echo -e "\n"
