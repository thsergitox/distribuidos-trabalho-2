#!/bin/bash
# Script para gerar todas as figuras do relatório IEEE

set -e

echo "🎨 Gerando figuras para o relatório..."
echo ""

# Verificar se matplotlib está instalado
if ! python3 -c "import matplotlib" 2>/dev/null; then
    echo "❌ Erro: matplotlib não está instalado"
    echo "Instale com: pip3 install matplotlib"
    uv pip install matplotlib
    exit 1
fi


# Gerar figura de arquitetura
echo "📊 Gerando figura 1: Arquitetura do sistema..."
python3 generate_arquitetura.py

echo ""

# Gerar figura de métricas
echo "📈 Gerando figura 2: Métricas de throughput..."
python3 generate_metricas.py

echo ""
echo "✅ Todas as figuras foram geradas com sucesso!"
echo ""
echo "📁 Arquivos gerados:"
echo "   - arquitetura.png (Figura 1: Arquitetura do Sistema)"
echo "   - metricas_throughput.png (Figura 2: Throughput vs Carga)"
echo "   - metricas_latencia.png (Figura 3: Latência vs Carga)"
echo ""
echo "🔄 Para compilar o relatório, execute:"
echo "   pdflatex relatorio.tex"
echo "   bibtex relatorio"
echo "   pdflatex relatorio.tex"
echo "   pdflatex relatorio.tex"
