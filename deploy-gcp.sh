#!/bin/bash

# ============================================================================
# Script de Deployment a Google Cloud Platform
# ============================================================================
#
# Este script despliega el sistema distribuido en GCP con:
# - 3 VMs en 3 regiones diferentes (us-central1, europe-west1, asia-east1)
# - Firewall configurado
# - Docker instalado y corriendo en cada VM
#
# Prerequisitos:
# - gcloud CLI instalado y autenticado
# - Variable GCP_PROJECT_ID configurada
# - Billing habilitado en el proyecto
#
# ============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GCP Deployment - Distributed Log System${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================================================
# PASO 1: Verificar prerequisitos
# ============================================================================
echo -e "\n${YELLOW}Step 1/8: Checking prerequisites...${NC}"

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}ERROR: gcloud CLI not found!${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GCP_PROJECT_ID not set!${NC}"
    echo "Run: export GCP_PROJECT_ID=your-project-id"
    exit 1
fi

echo -e "${GREEN}✓ gcloud CLI found${NC}"
echo -e "${GREEN}✓ Project ID: $GCP_PROJECT_ID${NC}"

# Configurar proyecto
gcloud config set project $GCP_PROJECT_ID

# ============================================================================
# PASO 2: Habilitar APIs
# ============================================================================
echo -e "\n${YELLOW}Step 2/8: Enabling required APIs...${NC}"
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerregistry.googleapis.com
echo -e "${GREEN}✓ APIs enabled${NC}"

# ============================================================================
# PASO 3: Configurar Firewall
# ============================================================================
echo -e "\n${YELLOW}Step 3/8: Creating firewall rules...${NC}"

# Eliminar reglas existentes si existen
gcloud compute firewall-rules delete allow-distributed-log --quiet 2>/dev/null || true
gcloud compute firewall-rules delete allow-ssh-distributed-log --quiet 2>/dev/null || true

# Crear regla para HTTP/HTTPS
gcloud compute firewall-rules create allow-distributed-log \
    --allow=tcp:80,tcp:443,tcp:8000-8100 \
    --target-tags=distributed-log \
    --description="Allow HTTP/HTTPS traffic for distributed log system"

# Crear regla para SSH
gcloud compute firewall-rules create allow-ssh-distributed-log \
    --allow=tcp:22 \
    --target-tags=distributed-log \
    --description="Allow SSH for distributed log system"

echo -e "${GREEN}✓ Firewall rules created${NC}"

# ============================================================================
# PASO 4: Build y Push de imagen Docker a GCR
# ============================================================================
echo -e "\n${YELLOW}Step 4/8: Building and pushing Docker image to GCR...${NC}"

IMAGE_NAME="gcr.io/$GCP_PROJECT_ID/distributed-log:latest"

# Build imagen
docker build -t $IMAGE_NAME .

# Configurar Docker para GCR
gcloud auth configure-docker --quiet

# Push imagen
docker push $IMAGE_NAME

echo -e "${GREEN}✓ Docker image pushed: $IMAGE_NAME${NC}"

# ============================================================================
# PASO 5: Crear VMs en diferentes regiones
# ============================================================================
echo -e "\n${YELLOW}Step 5/8: Creating VMs in 3 regions...${NC}"

# Definir regiones y zonas (MÁXIMA DISTANCIA GEOGRÁFICA)
# Node 1: Iowa, USA (Centro de Estados Unidos)
# Node 2: São Paulo, Brasil (Sur América)
# Node 3: Sydney, Australia (Oceanía)
# Distancias aproximadas: 10,000+ km entre cada par de nodos
declare -A REGIONS=(
    ["node1"]="us-central1-a"        # Iowa, USA
    ["node2"]="southamerica-east1-a" # São Paulo, Brasil
    ["node3"]="australia-southeast1-a" # Sydney, Australia
)

NODE_IDS=(8001 8002 8003)
VM_NAMES=(log-node-1 log-node-2 log-node-3)

# Eliminar VMs existentes si existen
for vm_name in "${VM_NAMES[@]}"; do
    echo "Checking if $vm_name exists..."
    gcloud compute instances delete $vm_name --quiet 2>/dev/null || true
done

# Crear startup script
cat > /tmp/startup-script.sh <<'EOF'
#!/bin/bash
set -e

echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

echo "=== Installing gcloud SDK ==="
apt-get update
apt-get install -y apt-transport-https ca-certificates gnupg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update
apt-get install -y google-cloud-sdk

echo "=== Configuring Docker for GCR ==="
gcloud auth configure-docker --quiet

echo "=== Pulling Docker image ==="
docker pull IMAGE_NAME_PLACEHOLDER

echo "=== Running container ==="
docker run -d \
  --name distributed-log \
  --restart unless-stopped \
  -p 80:80 \
  -e NODE_ID=NODE_ID_PLACEHOLDER \
  IMAGE_NAME_PLACEHOLDER

echo "=== Setup complete ==="
docker ps
EOF

# Crear VMs
for i in {0..2}; do
    vm_name="${VM_NAMES[$i]}"
    zone="${REGIONS[node$((i+1))]}"
    node_id="${NODE_IDS[$i]}"

    echo -e "${BLUE}Creating $vm_name in zone $zone (NODE_ID=$node_id)...${NC}"

    # Reemplazar placeholders en startup script
    sed "s|IMAGE_NAME_PLACEHOLDER|$IMAGE_NAME|g; s|NODE_ID_PLACEHOLDER|$node_id|g" \
        /tmp/startup-script.sh > /tmp/startup-$vm_name.sh

    # Crear VM
    gcloud compute instances create $vm_name \
        --zone=$zone \
        --machine-type=e2-micro \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --boot-disk-size=20GB \
        --boot-disk-type=pd-standard \
        --tags=distributed-log,http-server \
        --metadata-from-file=startup-script=/tmp/startup-$vm_name.sh \
        --scopes=https://www.googleapis.com/auth/cloud-platform

    echo -e "${GREEN}✓ $vm_name created${NC}"
done

# Cleanup
rm /tmp/startup*.sh

echo -e "${GREEN}✓ All VMs created${NC}"

# ============================================================================
# PASO 6: Esperar a que las VMs estén listas
# ============================================================================
echo -e "\n${YELLOW}Step 6/8: Waiting for VMs to be ready (60 seconds)...${NC}"
sleep 60

# ============================================================================
# PASO 7: Obtener IPs de las VMs
# ============================================================================
echo -e "\n${YELLOW}Step 7/8: Getting VM external IPs...${NC}"

declare -A VM_IPS

for i in {0..2}; do
    vm_name="${VM_NAMES[$i]}"
    zone="${REGIONS[node$((i+1))]}"

    external_ip=$(gcloud compute instances describe $vm_name \
        --zone=$zone \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

    VM_IPS[$vm_name]=$external_ip
    echo -e "${GREEN}$vm_name: $external_ip${NC}"
done

# ============================================================================
# PASO 8: Verificar deployment
# ============================================================================
echo -e "\n${YELLOW}Step 8/8: Verifying deployment...${NC}"

sleep 30  # Esperar a que los contenedores inicien

for i in {0..2}; do
    vm_name="${VM_NAMES[$i]}"
    ip="${VM_IPS[$vm_name]}"

    echo -e "${BLUE}Testing $vm_name ($ip)...${NC}"

    if curl -s -f "http://$ip/lamport_time" > /dev/null; then
        echo -e "${GREEN}✓ $vm_name is responding${NC}"
    else
        echo -e "${RED}✗ $vm_name is not responding yet${NC}"
    fi
done

# ============================================================================
# Resumen
# ============================================================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${BLUE}Node URLs:${NC}"
for i in {0..2}; do
    vm_name="${VM_NAMES[$i]}"
    ip="${VM_IPS[$vm_name]}"
    node_id="${NODE_IDS[$i]}"
    echo -e "  ${vm_name} (NODE_ID=${node_id}): ${GREEN}http://$ip${NC}"
done

echo -e "\n${BLUE}Useful commands:${NC}"
echo -e "  View logs:       ${YELLOW}gcloud compute ssh ${VM_NAMES[0]} --zone=${REGIONS[node1]} --command='docker logs distributed-log'${NC}"
echo -e "  SSH to node:     ${YELLOW}gcloud compute ssh ${VM_NAMES[0]} --zone=${REGIONS[node1]}${NC}"
echo -e "  Stop VMs:        ${YELLOW}./stop-gcp.sh${NC}"
echo -e "  Destroy all:     ${YELLOW}./destroy-gcp.sh${NC}"

echo -e "\n${BLUE}Testing:${NC}"
echo -e "  Send message:    ${YELLOW}curl -X POST 'http://${VM_IPS[${VM_NAMES[2]}]}/?message=Test_from_GCP'${NC}"
echo -e "  Check messages:  ${YELLOW}curl http://${VM_IPS[${VM_NAMES[0]}]}/messages${NC}"
