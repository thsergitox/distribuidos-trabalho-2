#!/bin/bash

# Script para probar el envío de mensajes al cluster

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing Message Sending${NC}"
echo -e "${GREEN}========================================${NC}"

# Verificar qué nodo es el líder
echo -e "\n${YELLOW}Checking leader...${NC}"
LEADER=$(curl -s http://localhost:8001/leader)
echo -e "Current leader: ${GREEN}$LEADER${NC}"

# Enviar 5 mensajes
echo -e "\n${YELLOW}Sending 5 messages to different nodes...${NC}"

echo -e "${BLUE}Message 1 → Node 1${NC}"
curl -X POST "http://localhost:8001/?message=Hello from test 1"
echo ""

sleep 1

echo -e "${BLUE}Message 2 → Node 2${NC}"
curl -X POST "http://localhost:8002/?message=Hello from test 2"
echo ""

sleep 1

echo -e "${BLUE}Message 3 → Node 3${NC}"
curl -X POST "http://localhost:8003/?message=Hello from test 3"
echo ""

sleep 1

echo -e "${BLUE}Message 4 → Node 1${NC}"
curl -X POST "http://localhost:8001/?message=Testing replication"
echo ""

sleep 1

echo -e "${BLUE}Message 5 → Node 2${NC}"
curl -X POST "http://localhost:8002/?message=Final message"
echo ""

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Messages sent successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Checking if all nodes have the same messages...${NC}"
echo -e "\n${BLUE}Node 1 state:${NC}"
curl -s http://localhost:8001/state
echo ""

echo -e "\n${BLUE}Node 2 state:${NC}"
curl -s http://localhost:8002/state
echo ""

echo -e "\n${BLUE}Node 3 state:${NC}"
curl -s http://localhost:8003/state
echo ""
