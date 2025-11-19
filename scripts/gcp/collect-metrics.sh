#!/bin/bash

# ============================================================================
# Script para recolectar métricas completas del sistema distribuido
# Para el relatório IEEE
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# IPs de los nodos (actualizar si cambian)
NODE1_IP="34.55.87.209"      # Iowa
NODE2_IP="34.95.212.100"     # São Paulo
NODE3_IP="35.201.29.184"     # Sydney (Leader)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Recolección de Métricas - Sistema Distribuido${NC}"
echo -e "${GREEN}Trabajo 2 - MC714 Sistemas Distribuídos${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================================================
# TEST 1: Latencia HTTP entre regiones
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 1: Latencia HTTP entre Regiones${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Midiendo latencia a Iowa (us-central1):${NC}"
for i in {1..5}; do
    time_ms=$( { time curl -s http://$NODE1_IP/lamport_time > /dev/null; } 2>&1 | grep real | awk '{print $2}')
    echo "  Intento $i: $time_ms"
done

echo -e "\n${CYAN}Midiendo latencia a São Paulo (southamerica-east1):${NC}"
for i in {1..5}; do
    time_ms=$( { time curl -s http://$NODE2_IP/lamport_time > /dev/null; } 2>&1 | grep real | awk '{print $2}')
    echo "  Intento $i: $time_ms"
done

echo -e "\n${CYAN}Midiendo latencia a Sydney (australia-southeast1):${NC}"
for i in {1..5}; do
    time_ms=$( { time curl -s http://$NODE3_IP/lamport_time > /dev/null; } 2>&1 | grep real | awk '{print $2}')
    echo "  Intento $i: $time_ms"
done

# ============================================================================
# TEST 2: Throughput bajo carga sostenida (50 mensajes)
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 2: Throughput - 50 Mensajes Concurrentes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Enviando 50 mensajes concurrentes al líder (Sydney)...${NC}"
start_time=$(date +%s.%N)

for i in {1..50}; do
    curl -s -X POST "http://$NODE3_IP/?message=LoadTest_$i" > /dev/null &
done
wait

end_time=$(date +%s.%N)
duration=$(awk "BEGIN {printf \"%.3f\", $end_time - $start_time}")
throughput=$(awk "BEGIN {printf \"%.2f\", 50 / $duration}")

echo -e "${GREEN}✓ Mensajes enviados${NC}"
echo -e "  Tiempo total: ${duration}s"
echo -e "  Throughput: ${throughput} msg/s"

echo -e "\n${CYAN}Esperando 5 segundos para replicación...${NC}"
sleep 5

# Verificar replicación
echo -e "\n${CYAN}Verificando replicación en todos los nodos:${NC}"
node1_count=$(curl -s http://$NODE1_IP/messages | grep -c '"id"' || echo "0")
node2_count=$(curl -s http://$NODE2_IP/messages | grep -c '"id"' || echo "0")
node3_count=$(curl -s http://$NODE3_IP/messages | grep -c '"id"' || echo "0")

echo -e "  Node 1 (Iowa):      ${node1_count} mensajes"
echo -e "  Node 2 (São Paulo): ${node2_count} mensajes"
echo -e "  Node 3 (Sydney):    ${node3_count} mensajes"

if [ "$node1_count" == "$node2_count" ] && [ "$node2_count" == "$node3_count" ]; then
    echo -e "${GREEN}✓ Replicación consistente en todos los nodos${NC}"
else
    echo -e "${RED}✗ Inconsistencia detectada en la replicación${NC}"
fi

# ============================================================================
# TEST 3: Lamport Clock con escritores concurrentes
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 3: Reloj de Lamport - Escritores Concurrentes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Ronda 1: Enviando desde los 3 nodos simultáneamente...${NC}"
curl -s -X POST "http://$NODE1_IP/?message=Concurrent_Iowa_1" > /dev/null &
curl -s -X POST "http://$NODE2_IP/?message=Concurrent_Brazil_1" > /dev/null &
curl -s -X POST "http://$NODE3_IP/?message=Concurrent_Sydney_1" > /dev/null &
wait

sleep 3

echo -e "${CYAN}Ronda 2: Enviando otra ronda simultánea...${NC}"
curl -s -X POST "http://$NODE1_IP/?message=Concurrent_Iowa_2" > /dev/null &
curl -s -X POST "http://$NODE2_IP/?message=Concurrent_Brazil_2" > /dev/null &
curl -s -X POST "http://$NODE3_IP/?message=Concurrent_Sydney_2" > /dev/null &
wait

sleep 3

echo -e "${CYAN}Ronda 3: Enviando tercera ronda simultánea...${NC}"
curl -s -X POST "http://$NODE1_IP/?message=Concurrent_Iowa_3" > /dev/null &
curl -s -X POST "http://$NODE2_IP/?message=Concurrent_Brazil_3" > /dev/null &
curl -s -X POST "http://$NODE3_IP/?message=Concurrent_Sydney_3" > /dev/null &
wait

sleep 5

# Ver Lamport timestamps actuales
echo -e "\n${CYAN}Estado actual de los relojes de Lamport:${NC}"
lamport1=$(curl -s http://$NODE1_IP/lamport_time)
lamport2=$(curl -s http://$NODE2_IP/lamport_time)
lamport3=$(curl -s http://$NODE3_IP/lamport_time)

echo -e "  Node 1 (Iowa):      $lamport1"
echo -e "  Node 2 (São Paulo): $lamport2"
echo -e "  Node 3 (Sydney):    $lamport3"

# Ver últimos 10 mensajes con timestamps
echo -e "\n${CYAN}Últimos mensajes con Lamport timestamps (Node 1):${NC}"
curl -s http://$NODE1_IP/messages | grep -E '"(id|content|lamport_timestamp|node_id)"' | tail -30

# ============================================================================
# TEST 4: Latencia de replicación geográfica
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 4: Latencia de Replicación Geográfica${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Enviando mensaje marcado con timestamp...${NC}"
unique_msg="ReplicationTest_$(date +%s)"
timestamp_send=$(date +%s.%N)

curl -s -X POST "http://$NODE3_IP/?message=$unique_msg" > /dev/null

echo -e "Mensaje enviado: $unique_msg"
echo -e "Timestamp envío: $timestamp_send"

# Verificar cada 0.5s hasta que aparezca en todos los nodos
echo -e "\n${CYAN}Monitoreando aparición en cada nodo...${NC}"

for node_ip in $NODE1_IP $NODE2_IP $NODE3_IP; do
    echo -e "\nVerificando en $node_ip..."
    for i in {1..20}; do
        if curl -s "http://$node_ip/messages" | grep -q "$unique_msg"; then
            timestamp_recv=$(date +%s.%N)
            latency=$(awk "BEGIN {printf \"%.3f\", $timestamp_recv - $timestamp_send}")
            echo -e "  ${GREEN}✓ Mensaje replicado en ${latency}s${NC}"
            break
        fi
        sleep 0.5
    done
done

# ============================================================================
# TEST 5: Throughput con diferentes cargas
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 5: Throughput con Diferentes Cargas${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for load in 10 25 50 100; do
    echo -e "\n${CYAN}Probando con $load mensajes...${NC}"

    start=$(date +%s.%N)
    for i in $(seq 1 $load); do
        curl -s -X POST "http://$NODE3_IP/?message=Load${load}_Msg$i" > /dev/null &
    done
    wait
    end=$(date +%s.%N)

    duration=$(awk "BEGIN {printf \"%.3f\", $end - $start}")
    tput=$(awk "BEGIN {printf \"%.2f\", $load / $duration}")

    echo -e "  Carga: $load mensajes"
    echo -e "  Tiempo: ${duration}s"
    echo -e "  Throughput: ${tput} msg/s"

    sleep 3
done

# ============================================================================
# TEST 6: Estado final del sistema
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 6: Estado Final del Sistema${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${CYAN}Información de cada nodo:${NC}"

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
# Resumen
# ============================================================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}MÉTRICAS RECOLECTADAS EXITOSAMENTE${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}Datos obtenidos:${NC}"
echo -e "  ✓ Latencias HTTP entre regiones (5 muestras por región)"
echo -e "  ✓ Throughput con 50 mensajes concurrentes"
echo -e "  ✓ Convergencia de relojes de Lamport"
echo -e "  ✓ Latencia de replicación geográfica"
echo -e "  ✓ Throughput con cargas variables (10, 25, 50, 100 msg)"
echo -e "  ✓ Estado final del sistema distribuido"

echo -e "\n${BLUE}Regiones geográficas:${NC}"
echo -e "  • Iowa (us-central1-a)"
echo -e "  • São Paulo (southamerica-east1-a)"
echo -e "  • Sydney (australia-southeast1-a)"

echo -e "\n${BLUE}Distancias aproximadas:${NC}"
echo -e "  • Iowa ↔ São Paulo: ~8,000 km"
echo -e "  • Iowa ↔ Sydney: ~13,000 km"
echo -e "  • São Paulo ↔ Sydney: ~15,000 km"
echo -e "  • Total: ~36,000 km de separación"

echo -e "\n${GREEN}Listo para escribir el relatório IEEE! 📊${NC}"
echo -e "\n"
