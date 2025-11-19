# 🎨 Geração de Figuras para o Relatório IEEE

Este diretório contém scripts Python para gerar automaticamente as figuras do relatório.

## 📊 Figuras Geradas

### Figura 1: Arquitetura do Sistema (`arquitetura.png`)
- **Script:** `generate_arquitetura.py`
- **Descrição:** Diagrama mostrando os 3 nodos deployados em Iowa, São Paulo e Sydney
- **Conteúdo:**
  - Localização geográfica de cada nodo (flags + coordenadas)
  - IPs públicos de cada VM
  - Especificações das VMs (e2-micro, 1GB RAM)
  - Containers Docker com FastAPI + Lamport + Bully
  - Setas mostrando comunicação HTTP/REST entre nodos
  - Distâncias geodésicas: 8.000 km, 13.000 km, 15.000 km
  - Latências reais medidas: 19ms, 294ms, 652ms
  - Indicação do líder (Node 8003 - Sydney) com 👑

### Figura 2: Throughput sob Diferentes Cargas (`metricas_throughput.png`)
- **Script:** `generate_metricas.py`
- **Descrição:** Gráfico mostrando comportamento do throughput
- **Conteúdo:**
  - Throughput máximo: 26.19 msg/s (carga 50)
  - Degradação: 2.70 msg/s (carga 100) - queda de 90%
  - Linha vermelha marcando ponto de saturação (~50 msg)
  - Anotações com setas indicando pontos importantes

### Figura 3: Latência Média por Mensagem (`metricas_latencia.png`)
- **Script:** `generate_metricas.py`
- **Descrição:** Gráfico mostrando latência média (escala logarítmica)
- **Conteúdo:**
  - Latência cresce exponencialmente após 50 mensagens
  - Salto de 38.2ms → 369.8ms (10x)
  - Linha laranja marcando limite aceitável (100ms)
  - Anotação mostrando crescimento exponencial

## 🚀 Uso Rápido

### Gerar todas as figuras de uma vez:

```bash
cd relatorio
./generate_all_figures.sh
```

### Gerar figuras individualmente:

```bash
# Apenas arquitetura
python3 generate_arquitetura.py

# Apenas métricas
python3 generate_metricas.py
```

## 📦 Dependências

```bash
pip3 install matplotlib numpy
```

## 🔄 Compilar o Relatório com as Figuras

Depois de gerar as figuras, compile o PDF:

```bash
pdflatex relatorio.tex
bibtex relatorio
pdflatex relatorio.tex
pdflatex relatorio.tex
```

## 📐 Especificações Técnicas

- **Resolução:** 300 DPI (qualidade para publicação)
- **Formato:** PNG com fundo branco
- **Fontes:** Times New Roman (serif, estilo acadêmico)
- **Cores:** Paleta otimizada para impressão e projeção
- **Tamanho:** Otimizado para `\columnwidth` do IEEE conference format

## 📍 Localização no Relatório

### Figura 1 (arquitetura.png):
- **Seção:** 3.3 Deployment Geográfico
- **Linha:** ~125-129 do relatorio.tex
- **Label:** `\ref{fig:arquitetura}`
- **Caption:** "Arquitetura do sistema distribuído deployado em três regiões do GCP..."

### Figura 2 (metricas_throughput.png):
- **Seção:** 4.3 Convergência dos Relógios de Lamport (após Tabela 3)
- **Linha:** ~223-227 do relatorio.tex
- **Label:** `\ref{fig:metricas_throughput}`
- **Caption:** "Comportamento do throughput sob diferentes cargas..."

### Figura 3 (metricas_latencia.png):
- **Seção:** 4.3 Convergência dos Relógios de Lamport (após Figura 2)
- **Linha:** ~229-233 do relatorio.tex
- **Label:** `\ref{fig:metricas_latencia}`
- **Caption:** "Latência média por mensagem sob diferentes cargas..."

## 🎨 Personalização

Para ajustar as figuras, edite os scripts Python:

- **Cores:** Modifique as variáveis `color_*` no início dos scripts
- **Tamanho:** Ajuste `figsize` em `plt.subplots()`
- **DPI:** Modifique `plt.rcParams['figure.dpi']`
- **Fontes:** Altere `plt.rcParams['font.family']`

## 📊 Dados Usados

Os dados vêm das métricas reais coletadas do deployment GCP:

### Throughput (Tabela 2 do relatório):
```python
cargas = [10, 25, 50, 100]
throughput = [10.75, 19.61, 26.19, 2.70]  # msg/s
latencia_media = [93.0, 51.0, 38.2, 369.8]  # ms/msg
```

### Distâncias e Latências (Tabela 1 do relatório):
```python
Iowa ↔ São Paulo: 8.000 km, 294 ms
Iowa ↔ Sydney: 13.000 km, 652 ms
São Paulo ↔ Sydney: 15.000 km, 19 ms
```

## 🐛 Troubleshooting

### Erro: "ModuleNotFoundError: No module named 'matplotlib'"
```bash
pip3 install matplotlib numpy
```

### Figuras não aparecem no PDF compilado
1. Verifique que `arquitetura.png` e `metricas.png` existem no diretório `relatorio/`
2. Compile com `pdflatex` (não `latex`)
3. Certifique-se que o pacote `graphicx` está incluído no `.tex`

### Fontes não aparecem corretamente
- Times New Roman pode não estar disponível em todos os sistemas
- Alternativa: O matplotlib usará a fonte serif padrão disponível

## ✅ Checklist

- [ ] matplotlib e numpy instalados
- [ ] Scripts executados sem erros
- [ ] `arquitetura.png` gerado (deve ter ~1200x800px)
- [ ] `metricas.png` gerado (deve ter ~1200x800px)
- [ ] Figuras aparecem corretamente no PDF compilado
- [ ] Resolução é adequada (300 DPI, sem pixelização)
- [ ] Cores são visíveis tanto em tela quanto impressas

---

**Autores:** Sergio Pezo (298813) e José Victor (245511)
**Disciplina:** MC714 - Sistemas Distribuídos - Unicamp 2025
