# Arquitectura del Sistema Distribuido

## 🌍 Distribución Geográfica Global

### Regiones Seleccionadas (Máxima Distancia)

```
┌─────────────────────────────────────────────────────────────┐
│                    DISTRIBUCIÓN GLOBAL                       │
└─────────────────────────────────────────────────────────────┘

🇺🇸 Node 1: Iowa, USA (us-central1-a)
   Latitud: 41.8780° N
   Longitud: 93.0977° W

🇧🇷 Node 2: São Paulo, Brasil (southamerica-east1-a)
   Latitud: 23.5505° S
   Longitud: 46.6333° W

🇦🇺 Node 3: Sydney, Australia (australia-southeast1-a)
   Latitud: 33.8688° S
   Longitud: 151.2093° E
```

### Distancias Geográficas

| Desde → Hasta | Distancia (km) | Latencia Estimada (ms) |
|---------------|----------------|------------------------|
| Iowa → São Paulo | ~9,500 km | 150-200 ms |
| Iowa → Sydney | ~13,300 km | 200-250 ms |
| São Paulo → Sydney | ~13,600 km | 250-300 ms |

**Total de distancia recorrida:** >36,000 km (¡casi la circunferencia de la Tierra!)

### ¿Por qué estas regiones?

1. **Máxima separación geográfica:**
   - Cubrimos 3 continentes diferentes
   - Hemisferios norte y sur representados
   - Múltiples zonas horarias (diferencia de ~15 horas entre Iowa y Sydney)

2. **Simula un sistema distribuido REAL:**
   - Latencias altas (150-300ms) similares a aplicaciones globales reales
   - Diferentes condiciones de red
   - Prueba real del algoritmo Bully y Lamport bajo condiciones adversas

3. **Demuestra propiedades del sistema:**
   - **Reloj Lógico de Lamport:** NO depende de sincronización de relojes físicos
   - **Algoritmo Bully:** Funciona incluso con latencias altas
   - **Tolerancia a fallos:** Si una región falla, las otras 2 continúan

## 🏗️ Arquitectura de Deployment

```
┌──────────────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                          │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  us-central1-a      │  │ southamerica-east1-a│  │australia-southeast1-a│
│  (Iowa, USA)        │  │ (São Paulo, Brasil) │  │  (Sydney, Australia)│
│  IP: 34.55.87.209   │  │  IP: 34.95.212.100  │  │  IP: 35.201.29.184  │
│                     │  │                     │  │                     │
│  ┌──────────────┐   │  │  ┌──────────────┐   │  │  ┌──────────────┐   │
│  │ VM: e2-micro │   │  │  │ VM: e2-micro │   │  │  │ VM: e2-micro │   │
│  │ 2 vCPU       │   │  │  │ 2 vCPU       │   │  │  │ 2 vCPU       │   │
│  │ 1GB RAM      │   │  │  │ 1GB RAM      │   │  │  │ 1GB RAM      │   │
│  │ 20GB Disk    │   │  │  │ 20GB Disk    │   │  │  │ 20GB Disk    │   │
│  │              │   │  │  │              │   │  │  │              │   │
│  │ Docker:      │   │  │  │ Docker:      │   │  │  │ Docker:      │   │
│  │ - FastAPI    │   │  │  │ - FastAPI    │   │  │  │ - FastAPI    │   │
│  │ - Lamport    │   │  │  │ - Lamport    │   │  │  │ - Lamport    │   │
│  │ - Bully      │   │  │  │ - Bully      │   │  │  │ - Bully      │   │
│  │              │   │  │  │              │   │  │  │              │   │
│  │ NODE_ID:8001 │   │  │  │ NODE_ID:8002 │   │  │  │ NODE_ID:8003 │   │
│  │ Port: 80     │   │  │  │ Port: 80     │   │  │  │ Port: 80     │   │
│  │              │   │  │  │              │   │  │  │              │   │
│  │ OTHER_SERVERS│   │  │  │ OTHER_SERVERS│   │  │  │ OTHER_SERVERS│   │
│  │ = "IPs:..."  │   │  │  │ = "IPs:..."  │   │  │  │ = "IPs:..."  │   │
│  └──────────────┘   │  │  └──────────────┘   │  │  └──────────────┘   │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
         │                        │                        │
         └────────────────────────┴────────────────────────┘
        Comunicación HTTP/REST usando IPs públicas
        (Internet - Latencias reales de 150-300ms)
```

**Nota Importante sobre Networking:**
- En **Docker local**: Los nodos usan nombres de contenedor (node1, node2, node3)
- En **GCP**: Los nodos usan IPs públicas pasadas via variable `OTHER_SERVERS`
- El código detecta automáticamente el entorno y se configura apropiadamente

## 🔄 Flujo de Comunicación

### 1. Elección de Líder (Algoritmo Bully)

```
Inicio: Todos los nodos inician simultáneamente

Node 8001 (Iowa):     "¿Hay alguien con ID mayor?"
                      → Consulta a 8002 (Brasil) [~180ms RTT]
                      → Consulta a 8003 (Sydney) [~230ms RTT]

Node 8002 (Brasil):   "¿Hay alguien con ID mayor?"
                      → Consulta a 8003 (Sydney) [~270ms RTT]

Node 8003 (Sydney):   "No hay nadie mayor, soy el líder"
                      → Notifica a todos [~250ms promedio]

Resultado: Node 8003 es el LÍDER
Tiempo total de elección: ~1-2 segundos
```

### 2. Replicación de Mensajes (Reloj Lógico de Lamport)

```
Cliente → Node 8001 (Iowa):
  POST /?message=Hello

Node 8001:
  1. Detecta que NO es líder
  2. Forward a Node 8003 (Sydney) [~230ms]

Node 8003 (Líder):
  1. Incrementa Lamport Clock: t=1
  2. Crea mensaje: {id: 2, lamport: 1, node: 8003}
  3. Replica en PARALELO:
     → Node 8001 (Iowa)   [~230ms]
     → Node 8002 (Brasil) [~270ms]

Node 8001 y 8002:
  1. Reciben mensaje con lamport=1
  2. Actualizan reloj: max(local, 1) + 1
  3. Guardan mensaje ordenado por Lamport
  4. Responden al líder

Tiempo total: ~500-600ms (incluyendo latencias globales)
```

## 📊 Métricas Observables

### Latencias Esperadas

| Operación | Latencia Estimada |
|-----------|-------------------|
| Lectura local (GET /messages) | 1-5 ms |
| Escritura en líder (POST /) | 10-20 ms |
| Replicación global completa | 300-600 ms |
| Elección de líder (re-election) | 1-2 segundos |
| Health check entre nodos | 150-300 ms |

### Propiedades Garantizadas

✅ **Consistencia Causal (Lamport):**
   - Si mensaje A → B (causalmente), entonces Lamport(A) < Lamport(B)
   - SIEMPRE, independientemente de latencias de red

✅ **Disponibilidad (Bully):**
   - Si 2 de 3 nodos están vivos, el sistema funciona
   - Re-elección automática en ~1-2 segundos

✅ **Tolerancia a Particiones:**
   - Cada nodo puede seguir operando localmente
   - Eventual consistency cuando la red se recupera

## 🔌 APIs Requeridas en GCP

Para que el deployment funcione correctamente, necesitas habilitar estas APIs:

```bash
# Compute Engine API - Para crear y gestionar VMs
gcloud services enable compute.googleapis.com

# Artifact Registry API - Para almacenar imágenes Docker (nuevo sistema)
gcloud services enable artifactregistry.googleapis.com

# Container Registry API - Para backward compatibility con gcr.io
gcloud services enable containerregistry.googleapis.com
```

**Nota:** Aunque usamos `gcr.io` en el código, Google Cloud internamente redirige a Artifact Registry, por lo que ambas APIs son necesarias.

## 💰 Costos Estimados (GCP)

```
VM e2-micro (3 instancias):
  - Precio: ~$6.11/mes por instancia
  - Total VMs: ~$18.33/mes

Egress Traffic (datos saliendo de GCP):
  - Primeros 1GB/mes: Gratis
  - Siguiente 10TB: $0.12/GB
  - Estimado para testing: ~$5/mes

TOTAL ESTIMADO: ~$25/mes

Para este proyecto (algunas horas): < $1
```

## 🔒 Seguridad

### Firewall Rules

```
allow-distributed-log:
  - Protocolo: TCP
  - Puertos: 80, 443, 8000-8100
  - Fuente: 0.0.0.0/0 (cualquier IP)
  - Target: VMs con tag "distributed-log"

allow-ssh-distributed-log:
  - Protocolo: TCP
  - Puerto: 22
  - Fuente: 0.0.0.0/0
  - Target: VMs con tag "distributed-log"
```

### Mejoras de Seguridad (Producción)

⚠️ Para un sistema de producción, implementar:
- HTTPS con certificados TLS
- Autenticación entre nodos (tokens JWT)
- IP whitelisting (solo IPs de nodos conocidos)
- VPN o VPC peering privado
- Rate limiting
- DDoS protection (Cloud Armor)
