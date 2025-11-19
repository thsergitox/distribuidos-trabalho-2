``` mermaid
graph TB
    subgraph GCP["🌐 Google Cloud Platform"]
        direction LR

        subgraph IOWA["🇺🇸 us-central1-a<br/>Iowa, USA<br/>IP: 34.55.87.209"]
            direction TB
            VM1["VM: e2-micro<br/>2 vCPU | 1GB RAM<br/>20GB Disk"]
            DOCKER1["🐳 Docker Container<br/>- FastAPI<br/>- Lamport Clock<br/>- Bully Algorithm"]
            NODE1["NODE_ID: 8001<br/>Port: 80<br/>OTHER_SERVERS: IPs..."]
            VM1 --> DOCKER1
            DOCKER1 --> NODE1
        end

        subgraph SP["🇧🇷 southamerica-east1-a<br/>São Paulo, Brasil<br/>IP: 34.95.212.100"]
            direction TB
            VM2["VM: e2-micro<br/>2 vCPU | 1GB RAM<br/>20GB Disk"]
            DOCKER2["🐳 Docker Container<br/>- FastAPI<br/>- Lamport Clock<br/>- Bully Algorithm"]
            NODE2["NODE_ID: 8002<br/>Port: 80<br/>OTHER_SERVERS: IPs..."]
            VM2 --> DOCKER2
            DOCKER2 --> NODE2
        end

        subgraph SYD["🇦🇺 australia-southeast1-a<br/>Sydney, Austrália<br/>IP: 35.201.29.184"]
            direction TB
            VM3["VM: e2-micro<br/>2 vCPU | 1GB RAM<br/>20GB Disk"]
            DOCKER3["🐳 Docker Container<br/>- FastAPI<br/>- Lamport Clock<br/>- Bully Algorithm"]
            NODE3["👑 NODE_ID: 8003 (LÍDER)<br/>Port: 80<br/>OTHER_SERVERS: IPs..."]
            VM3 --> DOCKER3
            DOCKER3 --> NODE3
        end
    end

    %% Comunicação entre nodos
    NODE1 <-- "HTTP/REST<br/>~8.000 km<br/>294 ms" --> NODE2
    NODE2 <-- "HTTP/REST<br/>~15.000 km<br/>19 ms" --> NODE3
    NODE1 <-- "HTTP/REST<br/>~13.000 km<br/>652 ms" --> NODE3

    %% Estilos
    classDef nodeBox fill:#E8F4F8,stroke:#2E86AB,stroke-width:2px,color:#000
    classDef vmBox fill:#FFF,stroke:#2E86AB,stroke-width:1px,color:#000
    classDef dockerBox fill:#0db7ed,stroke:#0db7ed,stroke-width:2px,color:#fff
    classDef leaderBox fill:#FFD700,stroke:#FF8C00,stroke-width:3px,color:#000,font-weight:bold

    class IOWA,SP,SYD nodeBox
    class VM1,VM2,VM3 vmBox
    class DOCKER1,DOCKER2,DOCKER3 dockerBox
    class NODE3 leaderBox

    %% Nota no rodapé
    NOTE["📡 Comunicação HTTP/REST usando IPs públicos<br/>Internet - Latências reais medidas<br/>Distância total: ~36.000 km"]

    classDef noteBox fill:#FFFACD,stroke:#FFD700,stroke-width:2px,color:#000,font-style:italic
    class NOTE noteBox


```
