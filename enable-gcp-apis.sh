#!/bin/bash

# ============================================================================
# Script para habilitar las APIs necesarias en GCP
# ============================================================================
#
# Este script habilita todas las APIs requeridas para el deployment:
# - Compute Engine API (para crear VMs)
# - Artifact Registry API (para almacenar imágenes Docker)
# - Container Registry API (para backward compatibility)
#
# Uso:
#   export GCP_PROJECT_ID="tu-project-id"
#   ./enable-gcp-apis.sh
#
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Enabling GCP APIs${NC}"
echo -e "${GREEN}========================================${NC}"

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GCP_PROJECT_ID not set!${NC}"
    echo "Run: export GCP_PROJECT_ID=your-project-id"
    exit 1
fi

echo -e "\n${YELLOW}Setting project: $GCP_PROJECT_ID${NC}"
gcloud config set project $GCP_PROJECT_ID

echo -e "\n${YELLOW}Enabling Compute Engine API...${NC}"
gcloud services enable compute.googleapis.com
echo -e "${GREEN}✓ Compute Engine API enabled${NC}"

echo -e "\n${YELLOW}Enabling Artifact Registry API...${NC}"
gcloud services enable artifactregistry.googleapis.com
echo -e "${GREEN}✓ Artifact Registry API enabled${NC}"

echo -e "\n${YELLOW}Enabling Container Registry API...${NC}"
gcloud services enable containerregistry.googleapis.com
echo -e "${GREEN}✓ Container Registry API enabled${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}All APIs enabled successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Run deployment: ${GREEN}./deploy-gcp.sh${NC}"
echo -e "  2. Or wait a few seconds and retry if you just enabled the APIs"
