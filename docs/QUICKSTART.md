# 🚀 Guia Rápido de Deployment

## Testing Local (5 minutos)

```bash
# 1. Dar permissões
chmod +x *.sh

# 2. Iniciar cluster local
./scripts/local/test-local.sh

# 3. Esperar 10 segundos
sleep 10

# 4. Abrir dashboard no navegador
# Abre: http://localhost:8001/dashboard
# Ou testar com curl:
curl -X POST 'http://localhost:8001/?message=Test_Local'
curl http://localhost:8001/messages

# 5. Parar
./scripts/local/stop-local.sh
```

### 🎨 Dashboard Web

**A forma mais fácil de visualizar o sistema:**

```bash
# Depois de iniciar o cluster local, abra no seu navegador:
http://localhost:8001/dashboard
http://localhost:8002/dashboard
http://localhost:8003/dashboard
```

O dashboard mostra:
- Estado dos nodos em tempo real
- Lamport timestamps atuais
- Quem é o líder (com coroa 👑)
- Lista de mensagens ordenadas causalmente
- Formulário para enviar mensagens
- Auto-refresh a cada 3 segundos
```

## Deployment no GCP (10 minutos)

### Primeira vez (deployment completo)

```bash
# 1. Autenticar e configurar
gcloud auth login
export GCP_PROJECT_ID="trabalho2-477920"
gcloud config set project $GCP_PROJECT_ID

# 2. Deploy completo (leva ~5 minutos)
./scripts/gcp/deploy-gcp.sh

# 3. IMPORTANTE: Re-deploy de containers com IPs corretos
./scripts/gcp/redeploy-containers.sh

# 4. Verificar estado
./scripts/gcp/check-gcp-status.sh
```

### Se já tem as VMs criadas

```bash
# Somente re-deployar containers
export GCP_PROJECT_ID="trabalho2-477920"
./scripts/gcp/redeploy-containers.sh
```

## 🎨 Ver Dashboard no GCP

**OPÇÃO 1: Dashboard Web (RECOMENDADO para o vídeo)**

```bash
# Abra no seu navegador (substitua IPs pelos seus):
http://34.55.87.209/dashboard    # Node 1 - Iowa
http://34.95.212.100/dashboard   # Node 2 - São Paulo
http://35.201.29.184/dashboard   # Node 3 - Sydney
```

**O dashboard permite:**
- ✅ Ver o estado completo do cluster
- ✅ Enviar mensagens da interface
- ✅ Ver replicação em tempo real
- ✅ Identificar o líder com a coroa 👑
- ✅ Perfeito para gravar o vídeo de demonstração 📹

**OPÇÃO 2: Testing com curl**

```bash
# Obter IPs
./scripts/gcp/check-gcp-status.sh

# Variáveis de exemplo (substitua com os IPs reais)
IP1="34.55.87.209"    # Iowa
IP2="34.95.212.100"   # São Paulo
IP3="35.201.29.184"   # Sydney

# Enviar mensagens
curl -X POST "http://$IP3/?message=Test1_from_Sydney"
curl -X POST "http://$IP1/?message=Test2_from_Iowa"
curl -X POST "http://$IP2/?message=Test3_from_Brazil"

# Verificar replicação (todos devem ter as 3 mensagens)
curl http://$IP1/messages | jq
curl http://$IP2/messages | jq
curl http://$IP3/messages | jq

# Ver Lamport timestamps
curl http://$IP1/lamport_time
curl http://$IP2/lamport_time
curl http://$IP3/lamport_time

# Ver quem é o líder (deve ser 8003)
curl http://$IP1/leader
curl http://$IP2/leader
curl http://$IP3/leader
```

## Debugging

```bash
# Ver logs de um nodo específico
./scripts/gcp/debug-node.sh 1   # Iowa
./scripts/gcp/debug-node.sh 2   # São Paulo
./scripts/gcp/debug-node.sh 3   # Sydney

# SSH a uma VM
gcloud compute ssh log-node-1 --zone=us-central1-a

# Ver logs do container
gcloud compute ssh log-node-1 --zone=us-central1-a \
  --command='docker logs distributed-log --tail 100'

# Ver containers rodando
gcloud compute ssh log-node-1 --zone=us-central1-a \
  --command='docker ps'
```

## Limpar Tudo

```bash
# Destruir toda a infraestrutura
export GCP_PROJECT_ID="trabalho2-477920"
./scripts/gcp/destroy-gcp.sh
```

## Troubleshooting

### Problema: Os nodos não se veem entre si

```bash
# Solução: Re-deployar containers
./scripts/gcp/redeploy-containers.sh
```

### Problema: Node 3 (Sydney) não responde

```bash
# Ver o que está acontecendo
./scripts/gcp/debug-node.sh 3

# Se for problema de startup, esperar 2-3 minutos mais
# Ou SSH manualmente e reiniciar container
gcloud compute ssh log-node-3 --zone=australia-southeast1-a
docker restart distributed-log
docker logs distributed-log
```

### Problema: Cada nodo acha que é o líder

```bash
# Isso significa que OTHER_SERVERS não está configurado
# Solução:
./scripts/gcp/redeploy-containers.sh
```

## Variáveis de Ambiente Importantes

```bash
# GCP Project ID (SEMPRE necessário)
export GCP_PROJECT_ID="trabalho2-477920"

# NODE_ID (automático em scripts, manual se deployar manualmente)
export NODE_ID=8001

# OTHER_SERVERS (automático em redeploy-containers.sh)
export OTHER_SERVERS="34.55.87.209:80:8001,34.95.212.100:80:8002,35.201.29.184:80:8003"
```

## Fluxo Completo para o Projeto

```bash
# 1. Testing local primeiro
./scripts/local/test-local.sh
sleep 10
./scripts/local/test-send-messages.sh
./scripts/local/stop-local.sh

# 2. Deploy no GCP
export GCP_PROJECT_ID="trabalho2-477920"
./scripts/gcp/deploy-gcp.sh
./scripts/gcp/redeploy-containers.sh

# 3. Verificar
./scripts/gcp/check-gcp-status.sh

# 4. Fazer testes para o vídeo
# (enviar mensagens, mostrar replicação, mostrar Lamport, etc.)

# 5. Limpar quando terminar
./scripts/gcp/destroy-gcp.sh
```

## Checklist do Projeto

- [x] Implementar Lamport Clock
- [x] Implementar Algoritmo Bully
- [x] Testing local funcional
- [ ] Deploy no GCP exitoso
- [ ] Provas de replicação funcionando
- [ ] Vídeo de demonstração (5 minutos)
- [ ] Relatório IEEE (6 páginas)
- [ ] Enviar antes de 17/11/2025

## URLs Úteis

- **Console GCP:** https://console.cloud.google.com
- **Projeto:** https://console.cloud.google.com/home/dashboard?project=trabalho2-477920
- **VMs:** https://console.cloud.google.com/compute/instances?project=trabalho2-477920
