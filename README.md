# Sistema Distribuido de Log con Ordenación Causal

Sistema distribuido que implementa los algoritmos de **Reloj Lógico de Lamport** y **Algoritmo Bully** para elección de líder, con replicación de mensajes entre 3 nodos geográficamente distribuidos.

[![Python](https://img.shields.io/badge/Python-3.9-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Latest-green.svg)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![GCP](https://img.shields.io/badge/GCP-Deployed-orange.svg)](https://cloud.google.com/)

## 📋 Descripción

Este proyecto implementa un sistema de log distribuido que garantiza:
- **Ordenación causal de mensajes** mediante Reloj Lógico de Lamport
- **Elección automática de líder** mediante Algoritmo Bully
- **Replicación de mensajes** entre todos los nodos del cluster
- **Tolerancia a fallos** con re-elección automática de líder
- **Dashboard web interactivo** para visualización en tiempo real

## 🚀 Inicio Rápido

### Testing Local (Docker)

```bash
# 1. Iniciar cluster de 3 nodos
./scripts/local/test-local.sh

# 2. Abrir dashboard en el navegador
open http://localhost:8001/dashboard

# 3. Detener cluster
./scripts/local/stop-local.sh
```

### Deployment en GCP

```bash
# 1. Configurar proyecto
export GCP_PROJECT_ID="tu-proyecto-id"

# 2. Deploy completo
./scripts/gcp/deploy-gcp.sh

# 3. Re-deploy de contenedores con IPs correctas
./scripts/gcp/redeploy-containers.sh

# 4. Verificar estado
./scripts/gcp/check-gcp-status.sh
```

## 🎨 Dashboard Web

Accede al dashboard interactivo:
- **Local:** `http://localhost:8001/dashboard`
- **GCP:** `http://<IP-DEL-NODO>/dashboard`

El dashboard muestra:
- ✅ Estado de nodos en tiempo real
- ✅ Lamport timestamps actuales
- ✅ Identificación del líder (👑)
- ✅ Mensajes ordenados causalmente
- ✅ Formulario para enviar mensajes
- ✅ Auto-refresh cada 3 segundos

## 📁 Estructura del Proyecto

```
distribuidos-trabalho-2/
├── README.md                 # Este archivo
├── requirements.txt          # Dependencias Python
├── dockerfile               # Imagen Docker
├── docs/                    # Documentación completa
│   ├── ARCHITECTURE.md      # Arquitectura del sistema
│   ├── QUICKSTART.md        # Guía rápida
│   ├── gcp-setup.md         # Setup de GCP
│   ├── Trabalho.md          # Especificación del proyecto
│   └── PLAN_DETALLADO.md    # Plan de implementación
├── scripts/                 # Scripts de deployment y testing
│   ├── local/              # Scripts para Docker local
│   │   ├── test-local.sh
│   │   ├── stop-local.sh
│   │   └── test-send-messages.sh
│   ├── gcp/                # Scripts para Google Cloud Platform
│   │   ├── deploy-gcp.sh
│   │   ├── redeploy-containers.sh
│   │   ├── destroy-gcp.sh
│   │   ├── check-gcp-status.sh
│   │   ├── debug-node.sh
│   │   └── test-gcp-system.sh
│   └── monitoring/         # Scripts de monitoreo
│       └── watch-messages.sh
├── src/                    # Código fuente
│   ├── main.py            # Aplicación FastAPI principal
│   ├── server.py          # Modelo de servidor
│   ├── lamport_clock.py   # Implementación Reloj de Lamport
│   └── static/
│       └── dashboard.html # Dashboard web interactivo
└── legacy/                # Archivos legacy (no usados)
```

## 📚 Documentación Completa

Para más detalles, consulta:
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Arquitectura detallada del sistema
- **[docs/QUICKSTART.md](docs/QUICKSTART.md)** - Guía rápida de deployment
- **[docs/gcp-setup.md](docs/gcp-setup.md)** - Configuración de Google Cloud Platform

## 📊 Scripts Disponibles

### Scripts Locales (`scripts/local/`)
- `test-local.sh` - Iniciar cluster local de 3 nodos
- `stop-local.sh` - Detener cluster local
- `test-send-messages.sh` - Enviar mensajes de prueba

### Scripts GCP (`scripts/gcp/`)
- `deploy-gcp.sh` - Deployment completo en GCP
- `redeploy-containers.sh` - Re-deployar contenedores con nueva configuración
- `destroy-gcp.sh` - Eliminar toda la infraestructura de GCP
- `check-gcp-status.sh` - Verificar estado de todos los nodos
- `debug-node.sh <num>` - Ver logs detallados de un nodo
- `test-gcp-system.sh` - Suite de tests para GCP

### Scripts de Monitoreo (`scripts/monitoring/`)
- `watch-messages.sh <num>` - Monitorear mensajes en tiempo real

## 🎬 Roteiro para o Vídeo de Demonstração (5 minutos)

### Preparação

1. **Verificar deployment em GCP:**
```bash
export GCP_PROJECT_ID="trabalho2-477920"
./scripts/gcp/check-gcp-status.sh
```

2. **Abrir dashboards nos navegadores:**
```bash
# URLs dos dashboards (substitua com suas IPs)
http://34.55.87.209/dashboard    # Iowa (us-central1-a)
http://34.95.212.100/dashboard   # São Paulo (southamerica-east1-a)
http://35.201.29.184/dashboard   # Sydney (australia-southeast1-a)
```

### Roteiro de Demonstração

**Minuto 0-1: Introdução e Arquitetura**
- Apresentar o projeto: Sistema de log distribuído com Lamport Clock + Bully
- Mostrar os 3 nodos deployados em regiões geográficas distintas
- Explicar: 3 VMs em Iowa (EUA), São Paulo (Brasil), Sydney (Austrália)
- Total: ~36.000 km de separação

**Minuto 1-2: Algoritmo Bully - Eleição de Líder**
- Mostrar nos dashboards qual nodo é o líder atual (Node 3 - Sydney, ID 8003)
- Explicar: "O nodo com maior ID é eleito líder automaticamente"
- Mostrar comando para verificar líder:
```bash
curl http://34.55.87.209/leader  # Retorna 8003
```

**Minuto 2-4: Relógio de Lamport - Ordenação Causal**
- Enviar mensagens concorrentes de diferentes regiões:
```bash
# Terminal 1 - Iowa
curl -X POST "http://34.55.87.209/?message=Mensagem_Iowa_1"

# Terminal 2 - São Paulo
curl -X POST "http://34.95.212.100/?message=Mensagem_Brasil_1"

# Terminal 3 - Sydney (Líder)
curl -X POST "http://35.201.29.184/?message=Mensagem_Sydney_1"
```

- Mostrar nos dashboards:
  - Lamport timestamps incrementando (time: 1, 2, 3, ...)
  - Mensagens aparecendo em ordem causal
  - Replicação entre todos os nodos

- Enviar carga de teste:
```bash
./scripts/gcp/test-gcp-system.sh
```

- Mostrar métricas:
  - Throughput: ~27 msg/s
  - Latências: 19ms (SP), 294ms (Iowa), 652ms (Sydney)

**Minuto 4-5: Resultados e Conclusão**
- Mostrar dashboard com mensagens replicadas consistentemente
- Destacar Lamport timestamps preservando ordem causal
- Explicar limitações: saturação em 100 mensagens, single-leader
- Mencionar trabalho futuro: multi-leader, tolerância a falhas

### Comandos Úteis para Demonstração

```bash
# Ver mensagens em um nodo
curl http://34.55.87.209/messages | jq

# Ver Lamport time atual
curl http://34.55.87.209/lamport_time

# Enviar 10 mensagens concorrentes
for i in {1..10}; do
  curl -X POST "http://35.201.29.184/?message=Teste_$i" &
done

# Executar suite completa de testes
./scripts/gcp/test-gcp-system.sh

# Coletar métricas detalhadas
./scripts/gcp/collect-metrics.sh
```

### Dicas para Gravação

- ✅ Ambos os integrantes devem participar do vídeo
- ✅ Mostrar código-fonte brevemente (main.py, lamport_clock.py)
- ✅ Demonstrar funcionamento prático no GCP
- ✅ Explicar por que as latências são diferentes (distância geográfica)
- ✅ Mostrar consistência: mesmos dados em todos os nodos

## 👥 Autores

- Sergio Sebastian Pezo Jimenez - RA: 298813
- José Victor Santana Barbosa - RA: 245511

Projeto desenvolvido para a disciplina **MC714 - Sistemas Distribuídos**, Unicamp, 2º Semestre de 2025.

## 📄 Licencia

Este proyecto es para uso académico.
