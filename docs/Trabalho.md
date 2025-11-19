## MC714 – Sistemas Distribuídos
### 2º Semestre de 2025

---

## Trabalho 2
### Implementação de Algoritmos Distribuídos

---

**Carlos Alberto Astudillo Trujillo** (Professor)
**Juan Sebastian Orozco Monje** (Estudante de Mestrado - PED)
**Gabriel de Souza Rosa** (Estudante de Mestrado - PED)

---

Campinas, Outubro de 2025

---

### 1 Descrição Geral

Esta avaliação concentra-se na implementação de algoritmos de sistemas distribuídos em um ambiente de nuvem. O objetivo é selecionar alguns problemas de sistemas distribuídos e implementar uma solução utilizando tecnologias modernas de computação em nuvem tanto no seu desenvolvimento como para emular o sistema distribuído. Os estudantes deverão projetar, implantar e operar os seus sistemas na **Google Cloud Platform (GCP)** ou na **Microsoft Azure**, recorrendo à conta universitária disponibilizada e aos créditos disponibilizados para a disciplina na GCP. O trabalho deverá ser desenvolvido em **duplas**.

A entrega no Classroom consistirá em um único documento PDF contendo:

1.  Nome e RA dos participantes.
2.  Link para o repositório do trabalho no GitLab da disciplina. O repositório deve conter:
    *   O código-fonte da implementação, junto com instruções claras para sua compilação e execução (por exemplo, um Dockerfile ou um script de automação).
    *   Um relatório detalhado, como descrito na Seção 4.
3.  Link para um vídeo com a explicação e demonstração da solução.

#### Data de entrega

A data de entrega é no dia **17 de novembro de 2025**. Deverão subir os arquivos no Classroom dentro da tarefa do projeto. Não precisam duplicar as submissões, apenas uma pessoa por grupo deverá submeter o projeto. Recomenda-se submeter os trabalhos com antecedência e não esperar aos últimos minutos para a submissão.

---

### 2 Implementação

A equipe deve implementar no mínimo **dois algoritmos de sistemas distribuídos**. A escolha dos algoritmos é livre, permitindo explorar os conceitos que mais despertarem interesse. Exemplos de algoritmos que podem ser implementados incluem:

*   **Sincronização e Ordenação:**
    *   Relógio Lógico de Lamport. Exemplo de Stack: gRPC + mensagens; métricas: violações de ordem.
    *   Relógios Vetoriais. Exemplo de Stack: Pub/Sub (GCP) / Service Bus (Azure).

*   **Coordenação e Acordo:**
    *   Algoritmos de Exclusão Mútua para sistemas distribuídos. Exemplo de Stack: Kubernetes + gRPC.

*   **Eleição e Consenso:**
    *   Algoritmos de Eleição de Líder (Anel, Bully). Exemplo de Stack: health checks + gRPC.
    *   Protocolo de Consenso simples.

*   **Sistemas P2P:**
    *   Distributed Hash Table. Lookup de chaves em *O(log N)*.

*   **Agendamento, Balanceamento e Filas:**
    *   Leaky/Bucket Tokens Distribuído. Exemplo de Stack: Redis com scripts atômicos.

*   **Replicação:**
    *   Epidemic (Gossip) Replication. Exemplo de Stack: UDP entre pods; medir convergência.

#### Ambiente de Programação e Testes

O trabalho pode ser implementado em qualquer linguagem de programação, e o sistema de comunicação entre os componentes também é de livre escolha.

Para o ambiente de execução, a implementação deve ser feita em uma plataforma de nuvem (**Google Cloud Platform (GCP) ou Microsoft Azure**). Os nós do sistema distribuído devem ser simulados utilizando máquinas virtuais, com pelo menos 3 instâncias e 3 regiões diferentes.

---

### 3 Entregáveis

1.  Prepare um relatório descrevendo motivação, contextualização dos problemas, arquitetura do sistema (incluindo a nuvem), os algoritmos escolhidos, detalhes da implementação, cenários de experimentação, métricas de desempenho, análise de resultados e conclusões. É **obrigatório citar as fontes** de qualquer código utilizado e descrever as modificações feitas. Formato IEEE, coluna dupla, máx. 6 páginas.
2.  Grave um vídeo de aproximadamente 5 minutos demonstrando a implementação e a execução da solução na plataforma de nuvem escolhida. O vídeo deve mostrar o funcionamento dos algoritmos. Como é um trabalho em dupla, ambos os integrantes devem participar.

---

### 4 Avaliação

A avaliação do projeto será baseada nos critérios e pesos detalhados na tabela abaixo.

**Tabela 1: Critérios de Avaliação do Projeto**

| Critério | Ponderação (%) |
| :--- | :--- |
| Vídeo | 10 |
| Relatório | 30 |
| Arquitetura e Uso de Serviços de Nuvem | 20 |
| Implementação do Algoritmo 1 | 20 |
| Implementação do Algoritmo 2 | 20 |
| **Total** | **100** |
| **Bônus (opcional)** | **Pontos Adicionais** |

#### Itens Extras (Bônus)

Implementações que explorem conceitos adicionais, como os listados abaixo, podem receber pontuação extra:

*   **Algoritmos distribuídos adicionais.**
*   **Tolerância a Falhas:** Demonstrar como o sistema se recupera na presença de falhas (e.g., queda de um processo).
*   **Análise de Desempenho:** Medir e analisar métricas de performance da rede ou do sistema.
*   **Complementaridade dos algoritmos** para resolver um problema prático.