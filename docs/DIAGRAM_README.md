# 📊 Diagrama de Arquitetura Mermaid

Este arquivo contém o diagrama Mermaid minimalista da arquitetura do sistema distribuído.

## 📁 Arquivo

- **[architecture-diagram.mmd](architecture-diagram.mmd)** - Diagrama Mermaid da arquitetura

## 🎨 Características do Diagrama

### Design Minimalista:
- ✅ **Vertical** (top-down) - Fácil de ler
- ✅ **Monocromático** - Apenas preto, branco e cinza
- ✅ **Limpo** - Sem cores excessivas
- ✅ **Elegante** - Foco na informação

### Informações Mostradas:
- 3 Nodos em regiões diferentes (Iowa, São Paulo, Sydney)
- IPs públicos de cada VM
- IDs dos nodos (8001, 8002, 8003)
- Sydney marcado como LÍDER com 👑
- Especificações: e2-micro, 1GB RAM
- Stack: FastAPI + Lamport + Bully
- Conexões HTTP/REST com distâncias e latências
- Distância total: ~36.000 km

## 🖼️ Visualizar o Diagrama

### Opção 1: GitHub / GitLab
O diagrama renderiza automaticamente em Markdown:

```markdown
\`\`\`mermaid
[conteúdo do arquivo architecture-diagram.mmd]
\`\`\`
```

### Opção 2: VS Code
1. Instale a extensão "Markdown Preview Mermaid Support"
2. Abra `architecture-diagram.mmd`
3. Ctrl+Shift+V para preview

### Opção 3: Online (Mermaid Live Editor)
1. Acesse: https://mermaid.live/
2. Cole o conteúdo de `architecture-diagram.mmd`
3. O diagrama aparecerá automaticamente

### Opção 4: Exportar para PNG (para o relatório)

#### Método 1: Mermaid CLI (Recomendado)
```bash
# Instalar mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Gerar PNG
cd docs
mmdc -i architecture-diagram.mmd -o architecture.png -w 1200 -H 1600 -b white
```

#### Método 2: Mermaid Live Editor
1. Acesse https://mermaid.live/
2. Cole o diagrama
3. Clique em "Actions" → "PNG"
4. Salve como `architecture.png` em `relatorio/`

#### Método 3: VS Code com Extensão
1. Instale "Markdown PDF" ou "Mermaid Export"
2. Botão direito no diagrama → "Export to PNG"

## 📐 Especificações para o Relatório

Se for usar no relatório IEEE, configure:
- **Largura:** 1200px (suficiente para `\columnwidth`)
- **Altura:** 1600px (proporção vertical)
- **Fundo:** Branco
- **Formato:** PNG
- **DPI:** 300 (para impressão)

## 🔧 Personalizar o Diagrama

Edite `architecture-diagram.mmd` para ajustar:

### Trocar tema:
```
%%{init: {'theme':'neutral'}}%%  ← Atual (minimalista)
%%{init: {'theme':'default'}}%%  ← Com mais cores
%%{init: {'theme':'forest'}}%%   ← Verde
%%{init: {'theme':'dark'}}%%     ← Fundo escuro
```

### Ajustar fonte:
```
'themeVariables': { 'fontSize':'16px'}  ← Atual
'themeVariables': { 'fontSize':'18px'}  ← Maior
```

### Mudar estilo de conexões:
```
NODE1 -->  NODE2   Seta sólida
NODE1 -.-> NODE2   Seta pontilhada (atual)
NODE1 -.- NODE2    Linha pontilhada sem seta
```

## 🎯 Uso no Relatório

Se quiser usar este diagrama no relatório ao invés do gerado por Python:

1. **Gerar PNG:**
```bash
mmdc -i docs/architecture-diagram.mmd -o relatorio/arquitetura.png -w 1200 -H 1600 -b white
```

2. **O relatório já está configurado** para usar `arquitetura.png` (linha ~126 do relatorio.tex)

3. **Vantagem:** Fácil de editar (só texto), fica mais limpo

## 📚 Documentação Mermaid

- **Site oficial:** https://mermaid.js.org/
- **Syntax:** https://mermaid.js.org/syntax/flowchart.html
- **Temas:** https://mermaid.js.org/config/theming.html

## 🎨 Comparação: Mermaid vs Python

| Aspecto | Mermaid (architecture-diagram.mmd) | Python (generate_arquitetura.py) |
|---------|-----------------------------------|----------------------------------|
| **Edição** | ✅ Texto simples | ❌ Código Python |
| **Renderização** | ✅ Automática (GitHub/VS Code) | ❌ Precisa executar script |
| **Qualidade** | ✅ Vetorial (SVG) | ✅ Raster (PNG) |
| **Customização** | ⚠️ Limitado por Mermaid | ✅ Total controle |
| **Minimalista** | ✅ Perfeito | ⚠️ Depende do código |
| **Manutenção** | ✅ Fácil | ⚠️ Requer Python |

**Recomendação:** Use Mermaid para simplicidade e estética minimalista!

---

**Autores:** Sergio Pezo (298813) e José Victor (245511)
**MC714 - Sistemas Distribuídos - Unicamp 2025**
