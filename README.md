# Sistema Distribuido de Log con Ordenación Causal

Sistema distribuido que implementa los algoritmos de **Reloj Lógico de Lamport** y **Algoritmo Bully** para elección de líder, con replicación de mensajes.

## 📋 Descripción

Este proyecto implementa un sistema de log distribuido que garantiza:
- **Ordenación causal de mensajes** mediante Reloj Lógico de Lamport
- **Elección automática de líder** mediante Algoritmo Bully
- **Replicación de mensajes** entre todos los nodos del cluster
- **Tolerancia a fallos** con re-elección automática de líder

## 🏗️ Arquitectura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Node 1    │────▶│   Node 2    │────▶│   Node 3    │
│  (Follower) │     │  (LEADER)   │     │  (Follower) │
│  Port 8001  │◀────│  Port 8002  │◀────│  Port 8003  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
              Replicación de mensajes
```

### Algoritmos Implementados

#### 1. Reloj Lógico de Lamport
- Cada mensaje recibe un timestamp lógico único
- Garantiza ordenación causal: si A → B, entonces Lamport(A) < Lamport(B)
- Sincronización mediante regla: `time = max(local_time, remote_time) + 1`

#### 2. Algoritmo Bully (Elección de Líder)
- El nodo con mayor ID es siempre el líder
- Detección automática de fallos (health check cada 5 segundos)
- Re-elección automática cuando el líder cae

#### 3. Replicación Single-Leader
- Solo el líder acepta escrituras
- Followers redirigen mensajes al líder
- Líder replica a todos los followers

## 🚀 Inicio Rápido

### Requisitos
- Docker
- Docker Compose (opcional)
- Bash

### Opción 1: Cluster Local (Desarrollo)

```bash
# 1. Dar permisos de ejecución a los scripts
chmod +x test-local.sh stop-local.sh test-send-messages.sh

# 2. Iniciar cluster de 3 nodos
./test-local.sh

# 3. Esperar 10 segundos para que se elija líder

# 4. Enviar mensajes de prueba
./test-send-messages.sh

# 5. Ver logs de un nodo
docker logs -f node1

# 6. Detener cluster
./stop-local.sh
```

### Opción 2: Nodo Individual

```bash
# Build de la imagen
docker build -t distributed-log:latest .

# Ejecutar un nodo
docker run -d \
  --name node1 \
  -p 8001:80 \
  -e NODE_ID=8001 \
  distributed-log:latest
```

## 📡 API Endpoints

### Endpoints Públicos

#### `GET /`
Obtener un mensaje específico por ID.
```bash
curl "http://localhost:8001/?id=1"
```

#### `POST /`
Crear un nuevo mensaje (será replicado a todos los nodos).
```bash
curl -X POST "http://localhost:8001/?message=Hello World"
```
**Respuesta:**
```json
{
  "id": 2,
  "lamport_timestamp": 15,
  "node_id": 8002
}
```

#### `GET /state`
Ver el estado del nodo (ID, líder actual).
```bash
curl http://localhost:8001/state
```

#### `GET /dashboard`
**🎨 Dashboard Web Interactivo** - La mejor forma de visualizar el sistema.
```bash
# En el navegador, abre:
http://localhost:8001/dashboard
http://localhost:8002/dashboard
http://localhost:8003/dashboard
```

**Características:**
- ✅ **Visualización en tiempo real** del estado de todos los nodos
- ✅ **Enviar mensajes** directamente desde la interfaz
- ✅ **Ver mensajes ordenados** por Lamport timestamp
- ✅ **Auto-refresh** cada 3 segundos
- ✅ **Indicador visual** del nodo líder (👑)
- ✅ **Diseño responsive** perfecto para demos y videos 📹

#### `GET /leader`
Obtener el ID del líder actual.
```bash
curl http://localhost:8001/leader
```

#### `GET /health`
Health check del nodo.
```bash
curl http://localhost:8001/health
```

#### `GET /lamport_time`
Obtener el Lamport timestamp actual del nodo.
```bash
curl http://localhost:8001/lamport_time
# Respuesta: {"time":5,"node_id":8001}
```

#### `GET /messages`
Obtener todos los mensajes ordenados por Lamport timestamp.
```bash
curl http://localhost:8001/messages
```

### Endpoints Internos (Replicación)

#### `POST /message_received`
Recibir mensaje replicado desde el líder (uso interno).

#### `GET /leader_selected`
Notificación de nuevo líder (uso interno para Bully).

## 🧪 Testing

### Test 1: Envío de Mensajes
```bash
# Enviar mensaje a cualquier nodo (será redirigido al líder)
curl -X POST "http://localhost:8001/?message=Test 1"
curl -X POST "http://localhost:8002/?message=Test 2"
curl -X POST "http://localhost:8003/?message=Test 3"

# Verificar que todos tienen los mismos mensajes
curl http://localhost:8001/state
curl http://localhost:8002/state
curl http://localhost:8003/state
```

### Test 2: Tolerancia a Fallos (Algoritmo Bully)
```bash
# 1. Verificar quién es el líder
LEADER=$(curl -s http://localhost:8001/leader)
echo "Líder actual: $LEADER"

# 2. Matar al líder (debería ser node3 con ID 8003)
docker stop node3

# 3. Esperar 10 segundos (detección + elección)
sleep 10

# 4. Verificar nuevo líder (debería ser node2 con ID 8002)
NEW_LEADER=$(curl -s http://localhost:8001/leader)
echo "Nuevo líder: $NEW_LEADER"

# 5. Enviar mensaje con el nuevo líder
curl -X POST "http://localhost:8001/?message=After failover"

# 6. Restaurar el nodo original
docker start node3

# 7. Esperar 10 segundos (node3 se vuelve líder por tener mayor ID)
sleep 10

# 8. Verificar líder final
FINAL_LEADER=$(curl -s http://localhost:8001/leader)
echo "Líder final: $FINAL_LEADER"  # Debería ser 8003 nuevamente
```

### Test 3: Ordenación Causal (Lamport)
```bash
# Enviar mensajes concurrentes desde diferentes nodos
for i in {1..10}; do
  curl -X POST "http://localhost:8001/?message=Concurrent_$i" &
  curl -X POST "http://localhost:8002/?message=Concurrent_$i" &
  curl -X POST "http://localhost:8003/?message=Concurrent_$i" &
done
wait

# Los mensajes deberían estar ordenados por timestamp Lamport
# (verificar en los logs de cada nodo)
```

## 🐳 Deployment en GCP

### Prerequisitos
- Cuenta de Google Cloud Platform
- `gcloud` CLI instalado y autenticado (`gcloud auth login`)
- Proyecto GCP creado con billing habilitado
- Docker instalado localmente

### Opción 1: Deployment Automático (RECOMENDADO)

**Script completo que hace todo:**

```bash
# 1. Configurar proyecto
export GCP_PROJECT_ID="tu-proyecto-id"

# 2. Ejecutar deployment automático
./deploy-gcp.sh
```

Este script automáticamente:
- ✅ Habilita APIs necesarias (Compute Engine, Artifact Registry, Container Registry)
- ✅ Crea firewall rules
- ✅ Build y push de imagen Docker a GCR
- ✅ Crea 3 VMs en regiones distantes (Iowa, São Paulo, Sydney)
- ✅ Instala Docker en cada VM
- ✅ Inicia contenedores con configuración correcta

**IMPORTANTE:** El primer deployment puede fallar en la comunicación entre nodos. Si esto ocurre, ejecuta:

```bash
# Re-deploy de contenedores con IPs correctas
./redeploy-containers.sh
```

Este script:
- Rebuild la imagen con el fix más reciente
- Obtiene las IPs públicas de las VMs
- Recrea los contenedores pasando `OTHER_SERVERS` con las IPs correctas

### Opción 2: Deployment Manual Paso a Paso

```bash
# 1. Configurar proyecto
export GCP_PROJECT_ID="tu-proyecto-id"
gcloud config set project $GCP_PROJECT_ID

# 2. Habilitar APIs necesarias
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerregistry.googleapis.com

# 3. Crear firewall rules
gcloud compute firewall-rules create allow-distributed-log \
  --allow=tcp:80,tcp:443,tcp:8000-8100 \
  --target-tags=distributed-log

# 4. Build y push de imagen a GCR
docker build -t gcr.io/$GCP_PROJECT_ID/distributed-log:latest .
gcloud auth configure-docker
docker push gcr.io/$GCP_PROJECT_ID/distributed-log:latest

# 5. Crear VMs (esto toma 2-3 minutos)
# Ver sección "Creación Manual de VMs" más abajo

# 6. Una vez creadas las VMs, ejecutar redeploy
./redeploy-containers.sh
```

### Verificar Deployment

```bash
# Ver estado de los nodos
./check-gcp-status.sh
```

Deberías ver algo como:
```
log-node-1 (NODE_ID=8001)
✓ HTTP responding
  Lamport Time: {"time":0,"node_id":8001}
  Leader ID: 8003  ← Todos deberían tener el mismo líder

log-node-2 (NODE_ID=8002)
✓ HTTP responding
  Leader ID: 8003

log-node-3 (NODE_ID=8003)
✓ HTTP responding
  Leader ID: 8003  ← Este es el líder (mayor ID)
```

### Scripts Disponibles para GCP

| Script | Descripción |
|--------|-------------|
| `./deploy-gcp.sh` | Deployment inicial completo (crea VMs, firewall, etc.) |
| `./redeploy-containers.sh` | Re-deployar solo los contenedores con nueva configuración |
| `./check-gcp-status.sh` | Verificar estado de todos los nodos |
| `./debug-node.sh <num>` | Ver logs detallados de un nodo específico (ej: `./debug-node.sh 3`) |
| `./destroy-gcp.sh` | Eliminar toda la infraestructura de GCP |

### Testing en GCP

```bash
# Obtener IPs de las VMs (ejecutar check-gcp-status.sh primero)
# O manualmente:
IP1="34.55.87.209"    # log-node-1 (Iowa)
IP2="34.95.212.100"   # log-node-2 (São Paulo)
IP3="35.201.29.184"   # log-node-3 (Sydney)

# Enviar mensaje al líder (node 3)
curl -X POST "http://$IP3/?message=Hello_from_Sydney"

# Verificar que se replicó en todos los nodos
curl http://$IP1/messages
curl http://$IP2/messages
curl http://$IP3/messages

# Todos deberían mostrar el mismo mensaje con el mismo Lamport timestamp
```

### Deploy Manual en VM (Avanzado)

Si necesitas deployar manualmente en una VM específica:

```bash
# SSH a la VM
gcloud compute ssh log-node-1 --zone=us-central1-a

# Obtener IPs de TODAS las VMs primero
# IP1=... IP2=... IP3=...

# Parar contenedor viejo
docker stop distributed-log 2>/dev/null || true
docker rm distributed-log 2>/dev/null || true

# Pull imagen
gcloud auth configure-docker
docker pull gcr.io/$GCP_PROJECT_ID/distributed-log:latest

# Ejecutar contenedor con OTHER_SERVERS
docker run -d \
  --name distributed-log \
  --restart unless-stopped \
  -p 80:80 \
  -e NODE_ID=8001 \
  -e OTHER_SERVERS="$IP1:80:8001,$IP2:80:8002,$IP3:80:8003" \
  gcr.io/$GCP_PROJECT_ID/distributed-log:latest

# Verificar
docker ps
docker logs distributed-log --tail 50
```

## 📊 Estructura del Proyecto

```
.
├── main.py                    # Aplicación principal FastAPI
├── server.py                  # Modelo de servidor
├── lamport_clock.py          # Implementación Reloj Lógico (TODO)
├── metrics.py                # Colector de métricas (TODO)
├── dockerfile                # Imagen Docker
├── requirements.txt          # Dependencias Python
├── test-local.sh            # Script para testing local
├── stop-local.sh            # Script para detener cluster
├── test-send-messages.sh    # Script para enviar mensajes de prueba
└── README.md                # Este archivo
```

## 🔧 Variables de Entorno

| Variable  | Descripción                    | Ejemplo | Requerido |
|-----------|--------------------------------|---------|-----------|
| NODE_ID   | ID único del nodo              | 8001    | ✅ Sí     |
| OTHER_SERVERS | IPs de otros nodos (GCP)   | 34.55.87.209:80:8001,... | Solo en GCP |

**Formato de OTHER_SERVERS:**
```
ip1:puerto1:id1,ip2:puerto2:id2,ip3:puerto3:id3
```

**Ejemplo para GCP:**
```bash
OTHER_SERVERS="34.55.87.209:80:8001,34.95.212.100:80:8002,35.201.29.184:80:8003"
```

**Nota:** En Docker local, esta variable NO es necesaria. El sistema usa automáticamente los nombres de contenedores (node1, node2, node3).

## 📋 Tabla Original de Variables

| Variable  | Descripción                    | Ejemplo |
|-----------|--------------------------------|---------|
| NODE_ID   | ID único del nodo (requerido)  | 8001    |

## 📝 Logs

Los logs se muestran en stdout de cada contenedor:

```bash
# Ver logs en tiempo real
docker logs -f node1

# Ver últimas 100 líneas
docker logs --tail 100 node1

# Logs de todos los nodos
docker logs node1 > logs/node1.log
docker logs node2 > logs/node2.log
docker logs node3 > logs/node3.log
```

## 🐛 Troubleshooting

### Los nodos no se comunican
```bash
# Verificar que están en la misma red Docker
docker network inspect distributed-net

# Verificar conectividad
docker exec node1 ping -c 3 node2
docker exec node1 ping -c 3 node3
```

### No se elige líder
```bash
# Verificar logs de elección
docker logs node1 | grep -i "election\|leader"

# Forzar re-elección matando el líder actual
docker stop node3
```

### Mensajes no se replican
```bash
# Verificar que el nodo es líder
curl http://localhost:8001/leader

# Verificar que followers están vivos
curl http://localhost:8002/health
curl http://localhost:8003/health
```

## 📚 Referencias

- [Lamport Timestamps](https://lamport.azurewebsites.net/pubs/time-clocks.pdf) - Paper original de Leslie Lamport
- [Bully Algorithm](https://en.wikipedia.org/wiki/Bully_algorithm) - Wikipedia
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Documentation](https://docs.docker.com/)

## 👥 Autores

- Sergio Sebastian Pezo Jimenez - RA: 298813
- Estudiante 2 - RA: XXXXXX

Projeto desenvolvido para a disciplina **MC714 - Sistemas Distribuídos**, Unicamp, 2º Semestre de 2025.

## 📄 Licencia

Este proyecto es para uso académico.
