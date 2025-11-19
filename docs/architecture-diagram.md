``` mermaid
graph TD
    GCP["Google Cloud Platform<br/>Sistema Distribuído de Log"]

    GCP --> NODE1
    GCP --> NODE2
    GCP --> NODE3

    NODE1["🇺🇸 Node 1: Iowa, USA<br/>━━━━━━━━━━━━━━━━━<br/>IP: 34.55.87.209<br/>ID: 8001<br/>e2-micro · 1GB RAM<br/>FastAPI + Lamport + Bully"]

    NODE2["🇧🇷 Node 2: São Paulo, Brasil<br/>━━━━━━━━━━━━━━━━━<br/>IP: 34.95.212.100<br/>ID: 8002<br/>e2-micro · 1GB RAM<br/>FastAPI + Lamport + Bully"]

    NODE3["🇦🇺 Node 3: Sydney, Austrália<br/>━━━━━━━━━━━━━━━━━<br/>IP: 35.201.29.184<br/>ID: 8003 👑 LÍDER<br/>e2-micro · 1GB RAM<br/>FastAPI + Lamport + Bully"]

    NODE1 -.->|"HTTP/REST<br/>~8.000 km<br/>294 ms"| NODE2
    NODE2 -.->|"HTTP/REST<br/>~15.000 km<br/>19 ms"| NODE3
    NODE1 -.->|"HTTP/REST<br/>~13.000 km<br/>652 ms"| NODE3

    NOTE["Distância Total: ~36.000 km<br/>Replicação Single-Leader<br/>Comunicação via Internet"]

    NODE3 -.-> NOTE

    classDef rootStyle fill:#f9f9f9,stroke:#333,stroke-width:2px,color:#000
    classDef nodeStyle fill:#fff,stroke:#666,stroke-width:2px,color:#000,stroke-dasharray:0
    classDef leaderStyle fill:#fff,stroke:#000,stroke-width:3px,color:#000
    classDef noteStyle fill:#f5f5f5,stroke:#999,stroke-width:1px,color:#666,font-size:14px

    class GCP rootStyle
    class NODE1,NODE2 nodeStyle
    class NODE3 leaderStyle
    class NOTE noteStyle

```
