# MC714 - Sistemas Distribuídos
## Trabalho 2: Implementação de Algoritmos Distribuídos

---

## 📋 Informações da Equipe

**Integrantes:**
- **Sergio Sebastian Pezo Jimenez** - RA: 298813 - s298813@dac.unicamp.br
- **José Victor Santana Barbosa** - RA: 245511 - j245511@dac.unicamp.br

**Data de Entrega:** 17 de novembro de 2025

---

## 🔗 Links do Projeto

### Repositório GitLab
```
[ADICIONAR URL DO GITLAB DA DISCIPLINA]
```

**Estrutura do Repositório:**
- `src/` - Código-fonte (Python + FastAPI)
- `scripts/` - Scripts de deployment e testes
- `relatorio/` - Relatório IEEE em LaTeX
- `docs/` - Documentação completa
- `README.md` - Instruções de uso

### Vídeo de Demonstração
```
[ADICIONAR URL DO VÍDEO NO YOUTUBE/DRIVE]
```

**Duração:** ~5 minutos

**Conteúdo do Vídeo:**
- Demonstração do sistema deployado em GCP (3 regiões)
- Algoritmo Bully - Eleição de líder
- Relógio de Lamport - Ordenação causal
- Métricas de performance (latências, throughput)
- Análise de resultados

---

## 🎯 Algoritmos Implementados

### 1. Relógio Lógico de Lamport
**Objetivo:** Ordenação causal de eventos em sistema distribuído

**Implementação:**
- Classe `LamportClock` thread-safe com `threading.Lock`
- Incremento local: `time := time + 1`
- Atualização remota: `time := max(local, remote) + 1`
- Timestamp anexado a cada mensagem

**Tecnologias:**
- Python 3.9
- FastAPI (REST API)
- HTTP para comunicação entre nodos

**Métricas:**
- ✅ Ordenação causal preservada em 100% dos testes
- ✅ Timestamps monotonicamente crescentes
- ✅ Convergência sob concorrência

### 2. Algoritmo Bully
**Objetivo:** Eleição de líder em sistema distribuído

**Implementação:**
- Eleição baseada em ID do processo
- Nodo com maior ID assume liderança (Node 3 - Sydney, ID 8003)
- Arquitetura single-leader para replicação

**Tecnologias:**
- Python 3.9
- FastAPI (REST API)
- Health checks HTTP

**Métricas:**
- ✅ Líder corretamente identificado (ID 8003)
- ✅ Coordenação através do líder funcional

---

## ☁️ Arquitetura e Deployment em GCP

**Plataforma:** Google Cloud Platform (GCP)

**Regiões Geográficas (3 continentes):**
1. **us-central1-a** (Iowa, EUA) - Node 1 (ID 8001)
2. **southamerica-east1-a** (São Paulo, Brasil) - Node 2 (ID 8002)
3. **australia-southeast1-a** (Sydney, Austrália) - Node 3 (ID 8003)

**Separação Geográfica Total:** ~36.000 km

**Infraestrutura:**
- 3 VMs e2-micro (1 vCPU, 1GB RAM)
- Docker containers com FastAPI
- Startup scripts automáticos
- Configuração via variáveis de ambiente

**Latências Medidas (de Campinas):**
- São Paulo: 19ms (~90 km de distância)
- Iowa: 295ms (~8.000 km de distância)
- Sydney: 652ms (~18.000 km de distância)

---

## 📊 Resultados Experimentais

### Throughput sob Diferentes Cargas

| Carga (msg) | Tempo (s) | Throughput (msg/s) | Latência Média (ms) |
|-------------|-----------|-------------------|---------------------|
| 10          | 0.930     | 10.75             | 93.0                |
| 25          | 1.275     | 19.61             | 51.0                |
| 50          | 1.909     | 26.19             | 38.2                |
| 100         | 36.976    | 2.70              | 369.8               |

**Observações:**
- Throughput máximo: 26.19 msg/s (50 mensagens concorrentes)
- Degradação severa em 100 mensagens (90% de redução)
- Saturação devido a limitações de CPU (e2-micro, 1 vCPU)

### Lamport Clocks após Escritas Concorrentes

| Nodo          | Região     | Lamport Time |
|---------------|------------|--------------|
| Node 1 (8001) | Iowa       | 14           |
| Node 2 (8002) | São Paulo  | 4            |
| Node 3 (8003) | Sydney     | 104          |

**Observações:**
- Líder (Sydney) processa mais mensagens → maior incremento
- Ordenação causal preservada em todos os nodos
- Timestamps monotonicamente crescentes validam implementação

---

## 🚀 Como Executar

### Deployment Local (Docker)
```bash
./scripts/local/test-local.sh
# Acessar: http://localhost:8001/dashboard
```

### Deployment em GCP
```bash
export GCP_PROJECT_ID="trabalho2-477920"
./scripts/gcp/deploy-gcp.sh
./scripts/gcp/redeploy-containers.sh
./scripts/gcp/check-gcp-status.sh
```

### Executar Testes
```bash
./scripts/gcp/test-gcp-system.sh      # Suite completa
./scripts/gcp/collect-metrics.sh      # Métricas detalhadas
```

---

## 📖 Documentação

### Relatório IEEE
- Arquivo: `relatorio/relatorio.tex`
- Formato: IEEE conference, coluna dupla
- Páginas: 6 páginas
- Conteúdo:
  - Fundamentação teórica (Lamport, Bully, CAP theorem)
  - Metodologia de implementação
  - Experimentos e métricas
  - Análise de resultados
  - Trabalhos relacionados
  - Conclusões e trabalho futuro
- Bibliografia: 10 referências

### Documentação Técnica
- `docs/ARCHITECTURE.md` - Arquitetura detalhada
- `docs/QUICKSTART.md` - Guia rápido
- `docs/gcp-setup.md` - Setup GCP
- `README.md` - Instruções principais

---

## 🎬 Roteiro do Vídeo

**Minuto 0-1:** Introdução e arquitetura (3 regiões, 36.000 km)

**Minuto 1-2:** Algoritmo Bully - demonstração da eleição de líder

**Minuto 2-4:** Relógio de Lamport - ordenação causal com mensagens concorrentes

**Minuto 4-5:** Resultados, métricas e conclusão

---

## 📦 Entregáveis

✅ **Código-fonte** - Repositório GitLab completo
✅ **Relatório IEEE** - 6 páginas em PDF
✅ **Vídeo** - ~5 minutos de demonstração
✅ **Documentação** - README + docs técnicos
✅ **Scripts** - Deployment automatizado GCP

---

## 🏆 Itens Extras (Bônus)

✅ **Dashboard Web Interactivo** - Visualização em tempo real (HTML/CSS/JS)
✅ **Análise de Performance** - Latências WAN, throughput, saturação
✅ **Deployment Geodistribuído** - 3 continentes, 36.000 km de separação
✅ **Scripts de Automação** - Deployment, testes e métricas automatizados
✅ **Instrumentação Completa** - Métricas detalhadas de Lamport timestamps

---

## 📚 Referências Principais

1. L. Lamport, "Time, clocks, and the ordering of events in a distributed system", CACM, 1978.
2. H. Garcia-Molina, "Elections in a distributed computing system", IEEE TC, 1982.
3. M. Kleppmann, "Designing Data-Intensive Applications", O'Reilly, 2017.
4. E. Brewer, "Towards robust distributed systems" (CAP theorem), PODC, 2000.

---

**Projeto desenvolvido para MC714 - Sistemas Distribuídos**
**Instituto de Computação - Unicamp**
**2º Semestre de 2025**
