#!/usr/bin/env python3
"""
Script para gerar gráficos de métricas (throughput vs carga)
para o relatório IEEE.

Uso:
    python3 generate_metricas.py

Output:
    metricas_throughput.png - Gráfico de throughput
    metricas_latencia.png - Gráfico de latência
"""

import matplotlib.pyplot as plt
import numpy as np

# Configurar estilo para paper acadêmico
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman']
plt.rcParams['font.size'] = 10
plt.rcParams['figure.dpi'] = 300

# Dados da Tabela 2 do relatório
cargas = [10, 25, 50, 100]
throughput = [10.75, 19.61, 26.19, 2.70]
tempo = [0.930, 1.275, 1.909, 36.976]
latencia_media = [93.0, 51.0, 38.2, 369.8]

# ========== FIGURA 1: Throughput vs Carga ==========
fig1, ax1 = plt.subplots(figsize=(6, 4))

ax1.plot(cargas, throughput, 'o-', linewidth=2, markersize=8, color='#2E86AB', label='Throughput')
ax1.axvline(x=50, color='red', linestyle='--', linewidth=1, alpha=0.5, label='Ponto de saturação (~50 msg)')
ax1.set_xlabel('Carga (mensagens)', fontsize=11, fontweight='bold')
ax1.set_ylabel('Throughput (msg/s)', fontsize=11, fontweight='bold')
ax1.set_title('Throughput sob Diferentes Cargas', fontsize=12, fontweight='bold')
ax1.grid(True, alpha=0.3, linestyle='--')
ax1.legend(fontsize=9)
ax1.set_ylim(0, 30)

plt.tight_layout()
plt.savefig('metricas_throughput.png', dpi=300, bbox_inches='tight', facecolor='white')
plt.close()
print("✅ Figura 'metricas_throughput.png' gerada com sucesso!")

# ========== FIGURA 2: Latência Média vs Carga ==========
fig2, ax2 = plt.subplots(figsize=(6, 4))

ax2.plot(cargas, latencia_media, 's-', linewidth=2, markersize=8, color='#A23B72', label='Latência média')
ax2.axhline(y=100, color='orange', linestyle='--', linewidth=1, alpha=0.5, label='Limite aceitável (100ms)')
ax2.set_xlabel('Carga (mensagens)', fontsize=11, fontweight='bold')
ax2.set_ylabel('Latência Média (ms/msg)', fontsize=11, fontweight='bold')
ax2.set_title('Latência Média por Mensagem', fontsize=12, fontweight='bold')
ax2.grid(True, alpha=0.3, linestyle='--')
ax2.legend(fontsize=9)
ax2.set_yscale('log')  # Escala logarítmica para mostrar melhor a degradação

plt.tight_layout()
plt.savefig('metricas_latencia.png', dpi=300, bbox_inches='tight', facecolor='white')
plt.close()
print("✅ Figura 'metricas_latencia.png' gerada com sucesso!")

print("\n📊 Resumo:")
print("   - metricas_throughput.png: Throughput vs Carga")
print("   - metricas_latencia.png: Latência vs Carga")
print("   Resolução: 1800x1200px @ 300 DPI cada")
