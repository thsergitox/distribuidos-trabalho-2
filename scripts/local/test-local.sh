#!/bin/bash

# ============================================================================
# Script de Teste Local - Sistema Distribuído
# ============================================================================
#
# Este script cria um cluster de 3 nós Docker para testar localmente
# o sistema distribuído antes de fazer o deploy no GCP.
#
# Arquitetura:
#   - 3 contêineres Docker (node1, node2, node3)
#   - Rede Docker bridge personalizada (distributed-net)
#   - Portas mapeadas: 8001, 8002, 8003
#   - Cada nó tem um NODE_ID único
#
# Uso:
#   ./test-local.sh
#
# Para parar:
#   ./stop-local.sh
#
# ============================================================================

set -e  # Sair se algum comando falhar

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem Cor

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Distributed Log - Configuração de Teste Local${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================================================
# PASSO 1: Limpar contêineres anteriores
# ============================================================================
# Remove contêineres anteriores se existirem (evita conflitos de nomes)
echo -e "\n${YELLOW}Passo 1/6: Limpando contêineres antigos...${NC}"
docker rm -f node1 node2 node3 2>/dev/null || true

# ============================================================================
# PASSO 2: Build da imagem Docker
# ============================================================================
# Constrói a imagem a partir do Dockerfile no diretório atual
# Tag: distributed-log:latest
echo -e "\n${YELLOW}Passo 2/6: Construindo imagem Docker...${NC}"
docker build -t distributed-log:latest .

# ============================================================================
# PASSO 3: Criar rede Docker personalizada
# ============================================================================
# Rede bridge para que os contêineres se comuniquem entre si por nome
# Exemplo: node1 pode fazer ping em node2 diretamente
echo -e "\n${YELLOW}Passo 3/6: Criando rede Docker...${NC}"
docker network rm distributed-net 2>/dev/null || true
docker network create distributed-net

# ============================================================================
# PASSO 4: Iniciar os 3 nós do cluster
# ============================================================================
# Cada nó roda em um contêiner separado com:
#   - Nome único (node1, node2, node3)
#   - NODE_ID único (8001, 8002, 8003)
#   - Porta mapeada para o host (8001, 8002, 8003)
#   - Conectado à rede distributed-net
#
# O nó com maior ID (8003) será eleito como líder inicial

echo -e "\n${YELLOW}Passo 4/6: Iniciando Node 1 (porta 8001)...${NC}"
docker run -d \
  --name node1 \
  --network distributed-net \
  -p 8001:80 \
  -e NODE_ID=8001 \
  distributed-log:latest

echo -e "${YELLOW}Iniciando Node 2 (porta 8002)...${NC}"
docker run -d \
  --name node2 \
  --network distributed-net \
  -p 8002:80 \
  -e NODE_ID=8002 \
  distributed-log:latest

echo -e "${YELLOW}Iniciando Node 3 (porta 8003)...${NC}"
docker run -d \
  --name node3 \
  --network distributed-net \
  -p 8003:80 \
  -e NODE_ID=8003 \
  distributed-log:latest

# Aguardar até que os contêineres estejam prontos
echo -e "\n${YELLOW}Passo 5/6: Aguardando nós ficarem prontos...${NC}"
sleep 5

# Verificar que os contêineres estão rodando
echo -e "\n${YELLOW}Passo 6/6: Verificando status dos contêineres...${NC}"
docker ps --filter "name=node" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}CLUSTER LOCAL PRONTO!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}URLs dos Nós:${NC}"
echo -e "  Node 1: ${GREEN}http://localhost:8001${NC}"
echo -e "  Node 2: ${GREEN}http://localhost:8002${NC}"
echo -e "  Node 3: ${GREEN}http://localhost:8003${NC}"

echo -e "\n${BLUE}Comandos úteis:${NC}"
echo -e "  Verificar estado do nó:  ${YELLOW}curl http://localhost:8001/state${NC}"
echo -e "  Obter líder:             ${YELLOW}curl http://localhost:8001/leader${NC}"
echo -e "  Enviar mensagem:         ${YELLOW}curl -X POST 'http://localhost:8001/?message=Hello'${NC}"
echo -e "  Ver logs (node 1):       ${YELLOW}docker logs -f node1${NC}"
echo -e "  Parar cluster:           ${YELLOW}./stop-local.sh${NC}"

echo -e "\n${BLUE}Testando eleição de líder (automático em ~5-10 segundos)...${NC}"
