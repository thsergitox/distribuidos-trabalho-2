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
- `gcloud` CLI instalado
- Proyecto GCP creado

### Pasos de Deployment

```bash
# 1. Configurar proyecto
export GCP_PROJECT_ID="tu-proyecto-id"
gcloud config set project $GCP_PROJECT_ID

# 2. Build y push de imagen a GCR
docker build -t gcr.io/$GCP_PROJECT_ID/distributed-log:latest .
docker push gcr.io/$GCP_PROJECT_ID/distributed-log:latest

# 3. Crear VMs en 3 regiones diferentes
# Región 1: us-central1 (Iowa, USA)
gcloud compute instances create log-node-1 \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --tags=distributed-log,http-server \
  --metadata=NODE_ID=8001

# Región 2: europe-west1 (Belgium)
gcloud compute instances create log-node-2 \
  --zone=europe-west1-b \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --tags=distributed-log,http-server \
  --metadata=NODE_ID=8002

# Región 3: asia-east1 (Taiwan)
gcloud compute instances create log-node-3 \
  --zone=asia-east1-a \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --tags=distributed-log,http-server \
  --metadata=NODE_ID=8003

# 4. Configurar firewall
gcloud compute firewall-rules create allow-distributed-log \
  --allow=tcp:80,tcp:443,tcp:8000-8100 \
  --target-tags=distributed-log

# 5. SSH a cada VM y ejecutar el contenedor
# (Ver sección "Deploy Manual en VM" más abajo)
```

### Deploy Manual en VM

```bash
# SSH a la VM
gcloud compute ssh log-node-1 --zone=us-central1-a

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Autenticar con GCR
gcloud auth configure-docker

# Pull imagen
docker pull gcr.io/$GCP_PROJECT_ID/distributed-log:latest

# Ejecutar contenedor
docker run -d \
  --name distributed-log \
  --restart unless-stopped \
  -p 80:80 \
  -e NODE_ID=8001 \
  gcr.io/$GCP_PROJECT_ID/distributed-log:latest

# Verificar
docker ps
docker logs distributed-log
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
