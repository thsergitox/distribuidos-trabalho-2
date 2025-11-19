#!/bin/bash

# Script para destruir toda la infraestructura de GCP

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Destroying GCP Infrastructure${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GCP_PROJECT_ID not set!${NC}"
    exit 1
fi

gcloud config set project $GCP_PROJECT_ID

echo -e "\n${YELLOW}Deleting VMs...${NC}"
gcloud compute instances delete log-node-1 --zone=us-central1-a --quiet 2>/dev/null || true
gcloud compute instances delete log-node-2 --zone=southamerica-east1-a --quiet 2>/dev/null || true
gcloud compute instances delete log-node-3 --zone=australia-southeast1-a --quiet 2>/dev/null || true

echo -e "\n${YELLOW}Deleting firewall rules...${NC}"
gcloud compute firewall-rules delete allow-distributed-log --quiet 2>/dev/null || true
gcloud compute firewall-rules delete allow-ssh-distributed-log --quiet 2>/dev/null || true

echo -e "\n✓ Infrastructure destroyed"
echo "Note: Docker images in GCR are not deleted (to avoid rebuild)"
echo "To delete images: gcloud container images delete gcr.io/$GCP_PROJECT_ID/distributed-log:latest --quiet"
