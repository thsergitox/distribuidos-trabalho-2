#!/usr/bin/env python3
"""
Script para gerar diagrama de arquitetura do sistema distribuído
para o relatório IEEE.

Uso:
    python3 generate_arquitetura.py

Output:
    arquitetura.png (1200x800px, 300 DPI)
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, Circle, FancyArrowPatch
import numpy as np

# Configurar estilo para paper acadêmico
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman']
plt.rcParams['font.size'] = 9
plt.rcParams['figure.dpi'] = 300

# Criar figura
fig, ax = plt.subplots(figsize=(12, 8))
ax.set_xlim(0, 12)
ax.set_ylim(0, 8)
ax.axis('off')

# Título
ax.text(6, 7.5, 'Arquitetura do Sistema Distribuído - Deployment Global no GCP',
        ha='center', va='center', fontsize=14, fontweight='bold')

# Cores
color_node = '#E8F4F8'
color_border = '#2E86AB'
color_arrow = '#666666'

# Função para desenhar um nodo
def draw_node(ax, x, y, region, country, flag, ip, node_id, is_leader=False):
    # Box principal
    box = FancyBboxPatch((x-1, y-1.5), 2, 2.5,
                          boxstyle="round,pad=0.1",
                          edgecolor=color_border,
                          facecolor=color_node,
                          linewidth=2)
    ax.add_patch(box)

    # Flag e região
    ax.text(x, y+0.9, f'{flag} {region}', ha='center', va='center',
            fontsize=10, fontweight='bold')
    ax.text(x, y+0.6, country, ha='center', va='center',
            fontsize=8, style='italic')

    # IP
    ax.text(x, y+0.2, f'IP: {ip}', ha='center', va='center',
            fontsize=8, family='monospace')

    # Node ID
    leader_text = ' 👑 (Líder)' if is_leader else ''
    ax.text(x, y-0.1, f'Node ID: {node_id}{leader_text}', ha='center', va='center',
            fontsize=8, fontweight='bold', color='#A23B72')

    # VM specs
    ax.text(x, y-0.5, 'VM: e2-micro', ha='center', va='center', fontsize=7)
    ax.text(x, y-0.7, '1 vCPU, 1GB RAM', ha='center', va='center', fontsize=7)

    # Docker container
    docker_box = FancyBboxPatch((x-0.7, y-1.3), 1.4, 0.5,
                                boxstyle="round,pad=0.05",
                                edgecolor='#0db7ed',
                                facecolor='white',
                                linewidth=1)
    ax.add_patch(docker_box)
    ax.text(x, y-1.05, 'Docker: FastAPI', ha='center', va='center', fontsize=7)
    ax.text(x, y-1.25, 'Lamport + Bully', ha='center', va='center', fontsize=6)

# Desenhar os 3 nodos
draw_node(ax, 2, 4, 'Iowa', 'EUA', '🇺🇸', '34.55.87.209', '8001')
draw_node(ax, 6, 4, 'São Paulo', 'Brasil', '🇧🇷', '34.95.212.100', '8002')
draw_node(ax, 10, 4, 'Sydney', 'Austrália', '🇦🇺', '35.201.29.184', '8003', is_leader=True)

# Desenhar setas de comunicação com latências
def draw_arrow_with_label(ax, x1, y1, x2, y2, label, distance, latency, color='#2E86AB'):
    arrow = FancyArrowPatch((x1, y1), (x2, y2),
                           arrowstyle='<->', mutation_scale=20,
                           linewidth=2, color=color,
                           connectionstyle="arc3,rad=0.2")
    ax.add_patch(arrow)

    # Label com distância e latência
    mid_x, mid_y = (x1+x2)/2, (y1+y2)/2 + 0.3
    ax.text(mid_x, mid_y, label, ha='center', va='center',
            fontsize=7, fontweight='bold',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor=color, alpha=0.9))
    ax.text(mid_x, mid_y-0.3, f'{distance}', ha='center', va='center',
            fontsize=6, style='italic')
    ax.text(mid_x, mid_y-0.5, f'Latência: {latency}', ha='center', va='center',
            fontsize=6, color='#A23B72')

# Setas entre nodos
draw_arrow_with_label(ax, 3, 3.5, 5, 3.5,
                      'HTTP/REST', '~8.000 km', '294 ms', color='#0066CC')
draw_arrow_with_label(ax, 7, 3.5, 9, 3.5,
                      'HTTP/REST', '~15.000 km', '19 ms', color='#00AA00')
draw_arrow_with_label(ax, 3, 3, 9, 3,
                      'HTTP/REST', '~13.000 km', '652 ms', color='#CC0000')

# Legenda de distâncias
legend_y = 1.5
ax.text(6, legend_y+0.5, 'Distâncias Geodésicas e Latências Reais',
        ha='center', va='center', fontsize=10, fontweight='bold')

legend_items = [
    ('Iowa ↔ São Paulo:', '~8.000 km', '294 ms', '#0066CC'),
    ('São Paulo ↔ Sydney:', '~15.000 km', '19 ms', '#00AA00'),
    ('Iowa ↔ Sydney:', '~13.000 km', '652 ms', '#CC0000'),
]

for i, (route, distance, latency, color) in enumerate(legend_items):
    y_pos = legend_y - 0.3 - (i * 0.3)
    ax.text(3, y_pos, route, ha='left', va='center', fontsize=8, fontweight='bold')
    ax.text(5.5, y_pos, distance, ha='left', va='center', fontsize=8)
    ax.text(7.5, y_pos, f'Latência: {latency}', ha='left', va='center',
            fontsize=8, color=color, fontweight='bold')

# Nota sobre distância total
ax.text(6, 0.3, 'Distância Total: ~36.000 km (quase a circunferência da Terra!)',
        ha='center', va='center', fontsize=9, fontweight='bold',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='#FFFACD', edgecolor='#FFD700', linewidth=2))

# Salvar figura
plt.tight_layout()
plt.savefig('arquitetura.png', dpi=300, bbox_inches='tight', facecolor='white')
print("✅ Figura 'arquitetura.png' gerada com sucesso!")
print("   Resolução: 1200x800px @ 300 DPI")
print("   Mostra: 3 nodos em Iowa, São Paulo e Sydney com distâncias e latências")
