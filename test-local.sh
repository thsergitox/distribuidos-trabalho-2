#!/bin/bash

# ============================================================================
# Script de Testing Local - Sistema Distribuido
# ============================================================================
#
# Este script crea un cluster de 3 nodos Docker para probar localmente
# el sistema distribuido antes de desplegarlo en GCP.
#
# Arquitectura:
#   - 3 contenedores Docker (node1, node2, node3)
#   - Red Docker bridge personalizada (distributed-net)
#   - Puertos mapeados: 8001, 8002, 8003
#   - Cada nodo tiene un NODE_ID único
#
# Uso:
#   ./test-local.sh
#
# Para detener:
#   ./stop-local.sh
#
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Distributed Log - Local Test Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================================================
# PASO 1: Limpiar contenedores anteriores
# ============================================================================
# Elimina contenedores previos si existen (evita conflictos de nombres)
echo -e "\n${YELLOW}Step 1/6: Cleaning up old containers...${NC}"
docker rm -f node1 node2 node3 2>/dev/null || true

# ============================================================================
# PASO 2: Build de la imagen Docker
# ============================================================================
# Construye la imagen desde el Dockerfile en el directorio actual
# Etiqueta: distributed-log:latest
echo -e "\n${YELLOW}Step 2/6: Building Docker image...${NC}"
docker build -t distributed-log:latest .

# ============================================================================
# PASO 3: Crear red Docker personalizada
# ============================================================================
# Red bridge para que los contenedores se comuniquen entre sí por nombre
# Ejemplo: node1 puede hacer ping a node2 directamente
echo -e "\n${YELLOW}Step 3/6: Creating Docker network...${NC}"
docker network rm distributed-net 2>/dev/null || true
docker network create distributed-net

# ============================================================================
# PASO 4: Iniciar los 3 nodos del cluster
# ============================================================================
# Cada nodo corre en un contenedor separado con:
#   - Nombre único (node1, node2, node3)
#   - NODE_ID único (8001, 8002, 8003)
#   - Puerto mapeado al host (8001, 8002, 8003)
#   - Conectado a la red distributed-net
#
# El nodo con mayor ID (8003) será elegido como líder inicial

echo -e "\n${YELLOW}Step 4/6: Starting Node 1 (port 8001)...${NC}"
docker run -d \
  --name node1 \
  --network distributed-net \
  -p 8001:80 \
  -e NODE_ID=8001 \
  distributed-log:latest

echo -e "${YELLOW}Starting Node 2 (port 8002)...${NC}"
docker run -d \
  --name node2 \
  --network distributed-net \
  -p 8002:80 \
  -e NODE_ID=8002 \
  distributed-log:latest

echo -e "${YELLOW}Starting Node 3 (port 8003)...${NC}"
docker run -d \
  --name node3 \
  --network distributed-net \
  -p 8003:80 \
  -e NODE_ID=8003 \
  distributed-log:latest

# Esperar a que los contenedores estén listos
echo -e "\n${YELLOW}Step 5/6: Waiting for nodes to be ready...${NC}"
sleep 5

# Verificar que los contenedores están corriendo
echo -e "\n${YELLOW}Step 6/6: Verifying containers status...${NC}"
docker ps --filter "name=node" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}LOCAL CLUSTER READY!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}Node URLs:${NC}"
echo -e "  Node 1: ${GREEN}http://localhost:8001${NC}"
echo -e "  Node 2: ${GREEN}http://localhost:8002${NC}"
echo -e "  Node 3: ${GREEN}http://localhost:8003${NC}"

echo -e "\n${BLUE}Useful commands:${NC}"
echo -e "  Check node state:    ${YELLOW}curl http://localhost:8001/state${NC}"
echo -e "  Get leader:          ${YELLOW}curl http://localhost:8001/leader${NC}"
echo -e "  Send message:        ${YELLOW}curl -X POST 'http://localhost:8001/?message=Hello'${NC}"
echo -e "  View logs (node 1):  ${YELLOW}docker logs -f node1${NC}"
echo -e "  Stop cluster:        ${YELLOW}./stop-local.sh${NC}"

echo -e "\n${BLUE}Testing leader election (automatic in ~5-10 seconds)...${NC}"
