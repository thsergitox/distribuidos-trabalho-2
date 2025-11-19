# 🚀 Guía Rápida de Deployment

## Testing Local (5 minutos)

```bash
# 1. Dar permisos
chmod +x *.sh

# 2. Iniciar cluster local
./test-local.sh

# 3. Esperar 10 segundos
sleep 10

# 4. Abrir dashboard en el navegador
# Abre: http://localhost:8001/dashboard
# O probar con curl:
curl -X POST 'http://localhost:8001/?message=Test_Local'
curl http://localhost:8001/messages

# 5. Detener
./stop-local.sh
```

### 🎨 Dashboard Web

**La forma más fácil de visualizar el sistema:**

```bash
# Después de iniciar el cluster local, abre en tu navegador:
http://localhost:8001/dashboard
http://localhost:8002/dashboard
http://localhost:8003/dashboard
```

El dashboard muestra:
- Estado de los nodos en tiempo real
- Lamport timestamps actuales
- Quién es el líder (con corona 👑)
- Lista de mensajes ordenados causalmente
- Formulario para enviar mensajes
- Auto-refresh cada 3 segundos
```

## Deployment en GCP (10 minutos)

### Primera vez (deployment completo)

```bash
# 1. Autenticar y configurar
gcloud auth login
export GCP_PROJECT_ID="trabalho2-477920"
gcloud config set project $GCP_PROJECT_ID

# 2. Deploy completo (toma ~5 minutos)
./deploy-gcp.sh

# 3. IMPORTANTE: Re-deploy de contenedores con IPs correctas
./redeploy-containers.sh

# 4. Verificar estado
./check-gcp-status.sh
```

### Si ya tienes las VMs creadas

```bash
# Solo re-deployar contenedores
export GCP_PROJECT_ID="trabalho2-477920"
./redeploy-containers.sh
```

## 🎨 Ver Dashboard en GCP

**OPCIÓN 1: Dashboard Web (RECOMENDADO para el video)**

```bash
# Abre en tu navegador (reemplaza IPs con las tuyas):
http://34.55.87.209/dashboard    # Node 1 - Iowa
http://34.95.212.100/dashboard   # Node 2 - São Paulo
http://35.201.29.184/dashboard   # Node 3 - Sydney
```

**El dashboard te permite:**
- ✅ Ver el estado completo del cluster
- ✅ Enviar mensajes desde la interfaz
- ✅ Ver replicación en tiempo real
- ✅ Identificar el líder con la corona 👑
- ✅ Perfecto para grabar el video de demostración 📹

**OPCIÓN 2: Testing con curl**

```bash
# Obtener IPs
./check-gcp-status.sh

# Variables de ejemplo (reemplaza con las IPs reales)
IP1="34.55.87.209"    # Iowa
IP2="34.95.212.100"   # São Paulo
IP3="35.201.29.184"   # Sydney

# Enviar mensajes
curl -X POST "http://$IP3/?message=Test1_from_Sydney"
curl -X POST "http://$IP1/?message=Test2_from_Iowa"
curl -X POST "http://$IP2/?message=Test3_from_Brazil"

# Verificar replicación (todos deberían tener los 3 mensajes)
curl http://$IP1/messages | jq
curl http://$IP2/messages | jq
curl http://$IP3/messages | jq

# Ver Lamport timestamps
curl http://$IP1/lamport_time
curl http://$IP2/lamport_time
curl http://$IP3/lamport_time

# Ver quién es el líder (debería ser 8003)
curl http://$IP1/leader
curl http://$IP2/leader
curl http://$IP3/leader
```

## Debugging

```bash
# Ver logs de un nodo específico
./debug-node.sh 1   # Iowa
./debug-node.sh 2   # São Paulo
./debug-node.sh 3   # Sydney

# SSH a una VM
gcloud compute ssh log-node-1 --zone=us-central1-a

# Ver logs del contenedor
gcloud compute ssh log-node-1 --zone=us-central1-a \
  --command='docker logs distributed-log --tail 100'

# Ver contenedores corriendo
gcloud compute ssh log-node-1 --zone=us-central1-a \
  --command='docker ps'
```

## Limpiar Todo

```bash
# Destruir toda la infraestructura
export GCP_PROJECT_ID="trabalho2-477920"
./destroy-gcp.sh
```

## Troubleshooting

### Problema: Los nodos no se ven entre sí

```bash
# Solución: Re-deployar contenedores
./redeploy-containers.sh
```

### Problema: Node 3 (Sydney) no responde

```bash
# Ver qué está pasando
./debug-node.sh 3

# Si es problema de startup, esperar 2-3 minutos más
# O SSH manualmente y reiniciar contenedor
gcloud compute ssh log-node-3 --zone=australia-southeast1-a
docker restart distributed-log
docker logs distributed-log
```

### Problema: Cada nodo cree que es el líder

```bash
# Esto significa que OTHER_SERVERS no está configurado
# Solución:
./redeploy-containers.sh
```

## Variables de Entorno Importantes

```bash
# GCP Project ID (SIEMPRE necesario)
export GCP_PROJECT_ID="trabalho2-477920"

# NODE_ID (automático en scripts, manual si despliegas a mano)
export NODE_ID=8001

# OTHER_SERVERS (automático en redeploy-containers.sh)
export OTHER_SERVERS="34.55.87.209:80:8001,34.95.212.100:80:8002,35.201.29.184:80:8003"
```

## Flujo Completo para el Proyecto

```bash
# 1. Testing local primero
./test-local.sh
sleep 10
./test-send-messages.sh
./stop-local.sh

# 2. Deploy a GCP
export GCP_PROJECT_ID="trabalho2-477920"
./deploy-gcp.sh
./redeploy-containers.sh

# 3. Verificar
./check-gcp-status.sh

# 4. Hacer tests para el video
# (enviar mensajes, mostrar replicación, mostrar Lamport, etc.)

# 5. Limpiar cuando termines
./destroy-gcp.sh
```

## Checklist del Proyecto

- [x] Implementar Lamport Clock
- [x] Implementar Algoritmo Bully
- [x] Testing local funcional
- [ ] Deploy en GCP exitoso
- [ ] Pruebas de replicación funcionando
- [ ] Video de demostración (5 minutos)
- [ ] Relatório IEEE (6 páginas)
- [ ] Enviar antes del 17/11/2025

## URLs Útiles

- **Consola GCP:** https://console.cloud.google.com
- **Proyecto:** https://console.cloud.google.com/home/dashboard?project=trabalho2-477920
- **VMs:** https://console.cloud.google.com/compute/instances?project=trabalho2-477920
