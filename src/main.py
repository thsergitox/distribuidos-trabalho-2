import random
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import threading
import time
import requests
import os
from server import Server
from lamport_clock import LamportClock
import server


app = FastAPI()

# Servir arquivos estáticos (dashboard HTML)
# O path é relativo ao diretório de execução
import pathlib
static_path = pathlib.Path(__file__).parent / "static"
if static_path.exists():
    app.mount("/static", StaticFiles(directory=str(static_path)), name="static")

# Obter NODE_ID da variável de ambiente
NODE_ID_ENV = os.getenv("NODE_ID")
my_id = int(NODE_ID_ENV) if NODE_ID_ENV else None

# Inicializar Relógio Lógico de Lamport
lamport_clock = LamportClock()

# Configurar lista de servidores baseado no ambiente
# Prioridade: Variáveis de ambiente > Docker names (default)
# Variáveis de ambiente para GCP:
#   OTHER_SERVERS="34.55.87.209:80:8001,34.95.212.100:80:8002,35.201.29.184:80:8003"
OTHER_SERVERS_ENV = os.getenv("OTHER_SERVERS")

if OTHER_SERVERS_ENV:
    # Parse formato: "ip1:port1:id1,ip2:port2:id2,ip3:port3:id3"
    KNOWN_NODES = []
    for server_str in OTHER_SERVERS_ENV.split(","):
        parts = server_str.strip().split(":")
        if len(parts) == 3:
            KNOWN_NODES.append({
                "host": parts[0],
                "port": int(parts[1]),
                "id": int(parts[2])
            })
else:
    # Default para Docker local
    KNOWN_NODES = [
        {"host": "node1", "port": 80, "id": 8001},
        {"host": "node2", "port": 80, "id": 8002},
        {"host": "node3", "port": 80, "id": 8003},
    ]

servers = [
    Server(host=node["host"], port=node["port"], id=node["id"])
    for node in KNOWN_NODES
]


class Message(BaseModel):
    """
    Modelo de mensagem com suporte para Relógio Lógico de Lamport

    Attributes:
        id: ID único da mensagem (incremental)
        content: Conteúdo da mensagem
        lamport_timestamp: Timestamp lógico de Lamport
        node_id: ID do nó que criou a mensagem
        physical_timestamp: Timestamp físico (time.time()) para debugging
    """
    id: int
    content: str
    lamport_timestamp: int
    node_id: int
    physical_timestamp: float


messages = [
    # Mensagem inicial com timestamp Lamport = 0
    Message(
        id=1,
        content="Hello",
        lamport_timestamp=0,
        node_id=my_id if my_id else 0,
        physical_timestamp=time.time()
    ),
]

leader = None 
last_id = 1
def leader_server():
    """
    Obtém o objeto Server do líder atual

    Returns:
        Server: Objeto do líder, ou None se não há líder ou se EU sou o líder
    """
    global leader
    if leader is None:
        print(f"[Node {my_id}] leader_server(): leader is None")
        return None

    # Se EU sou o líder, não preciso buscar na lista
    if leader == my_id:
        print(f"[Node {my_id}] leader_server(): I am the leader")
        return None

    for server in servers:
        if server.id == leader:
            print(f"[Node {my_id}] leader_server(): Found leader {leader} at {server.url()}")
            return server

    print(f"[Node {my_id}] leader_server(): Leader {leader} not found in servers list!")
    print(f"[Node {my_id}] Available servers: {[(s.id, s.host) for s in servers]}")
    return None
@app.get("/")
async def get(id : int ):
    return next((msg for msg in messages if msg.id == id), None)

@app.post("/")
async def post(message: str):
    """
    Endpoint para criar uma nova mensagem

    Fluxo:
    1. Se não sou líder → reencaminhar ao líder
    2. Se sou líder → criar mensagem e replicar aos followers

    Args:
        message: Conteúdo da mensagem

    Returns:
        int: ID da mensagem criada (somente líder)
        dict: Resposta do líder (se forwarded)
        dict: Erro se não há líder disponível
    """
    print(f"[Node {my_id}] Received POST request, message='{message}', leader={leader}")

    # PASSO 1: Verificar se sou o líder
    if leader != my_id:
        print(f"[Node {my_id}] I'm not the leader ({leader}), forwarding...")
        leader_srv = leader_server()

        if leader_srv is None:
            print(f"[Node {my_id}] ERROR: No leader available!")
            return {"error": "No leader available"}, 503

        # Forward ao líder
        url = f"{leader_srv.url()}/?message={message}"
        try:
            response = requests.post(url, json={"message": message}, timeout=2)
            print(f"[Node {my_id}] Forwarded to leader, response: {response.status_code}")
            return response.json()
        except Exception as e:
            print(f"[Node {my_id}] ERROR: Leader not reachable: {e}")
            return {"error": "Leader not reachable"}, 503

    # PASSO 2: Sou o líder, criar mensagem
    global messages

    # IMPORTANTE: Incrementar relógio Lamport ANTES de criar a mensagem
    lamport_time = lamport_clock.increment()

    id = max(msg.id for msg in messages) + 1
    new_msg = Message(
        id=id,
        content=message,
        lamport_timestamp=lamport_time,
        node_id=my_id,
        physical_timestamp=time.time()
    )
    messages.append(new_msg)

    print(f"[Node {my_id}] Created message {id} with Lamport timestamp {lamport_time}, replicating to followers...")

    # PASSO 3: Replicar a todos os followers
    for server in servers:
        if server.id and server.id != my_id:
            url = f"{server.url()}/message_received"
            try:
                result = requests.post(url, json={"content": message, "id": id}, timeout=2)
                print(f"[Node {my_id}] ✓ Replicated message {id} to node {server.id}")
            except Exception as e:
                print(f"[Node {my_id}] ✗ Failed to replicate to node {server.id}: {e}")

    return id  

@app.post("/message_received")
async def message_received(message: Message):
    """
    Endpoint para receber mensagens replicadas do líder

    Fluxo:
    1. Atualizar relógio Lamport com max(local, remote) + 1
    2. Guardar mensagem
    3. Ordenar mensagens por timestamp Lamport

    Args:
        message: Mensagem replicada com todos os campos Lamport

    Returns:
        dict: Status e timestamp Lamport local atualizado
    """
    global messages, last_id

    # PASSO 1: Atualizar relógio Lamport
    local_lamport = lamport_clock.update(message.lamport_timestamp)

    print(f"[Node {my_id}] Received message {message.id} from leader, "
          f"Lamport: remote={message.lamport_timestamp}, local={local_lamport}")

    # PASSO 2: Guardar mensagem
    messages.append(message)
    last_id = max(msg.id for msg in messages)

    # PASSO 3: Ordenar mensagens por Lamport (desempate por node_id)
    messages.sort(key=lambda m: (m.lamport_timestamp, m.node_id))

    return {
        "status": "ok",
        "local_lamport": local_lamport
    }
@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard():
    """
    Endpoint para servir o dashboard HTML

    Returns:
        HTMLResponse: Dashboard interativo
    """
    dashboard_path = pathlib.Path(__file__).parent / "static" / "dashboard.html"
    with open(dashboard_path, "r") as f:
        return HTMLResponse(content=f.read())


@app.get("/state")
async def state():
    """Retorna estado do nó (ID, líder atual)"""
    return str(my_id) + " " + str(leader) + str(leader_server())


@app.get("/lamport_time")
async def get_lamport_time():
    """
    Retorna o timestamp Lamport atual do nó

    Returns:
        dict: Tempo Lamport atual
    """
    return {"time": lamport_clock.get_time(), "node_id": my_id}


@app.get("/messages")
async def get_all_messages():
    """
    Retorna todas as mensagens ordenadas por timestamp Lamport

    Returns:
        list: Lista de mensagens ordenadas causalmente
    """
    # Ordenar por Lamport (já deveriam estar ordenadas, mas por segurança)
    sorted_messages = sorted(messages, key=lambda m: (m.lamport_timestamp, m.node_id))
    return sorted_messages
            

@app.get("/leader")
def get_leader():
    return leader 

@app.get("/leader_selected")
def leader_selected(sleader = int):
    global leader
    print(f"Leader selected: {sleader}")
    leader = sleader


def check_leader():
    """
    Thread que verifica continuamente o estado do líder

    Responsabilidades:
    1. Verificar a cada 5 segundos se o líder está vivo
    2. Iniciar eleição se o líder cai
    3. Atualizar variável global 'leader' se detecta mudança
    """
    global leader
    print(f"[Node {my_id}] Starting leader health check (current leader: {leader})")

    while True:
        # Se EU sou o líder, não preciso fazer health check
        if leader == my_id:
            time.sleep(5)
            continue

        lserver = leader_server()

        # Caso 1: Não temos líder registrado
        if lserver is None and leader is None:
            print(f"[Node {my_id}] No leader, starting election")
            start_election()
        elif lserver is not None:
            # Caso 2: Temos líder, verificar se está vivo
            cleader = lserver.current_leader()

            if cleader is None:
                # O líder não responde, iniciar eleição
                print(f"[Node {my_id}] Leader {leader} not responding, starting election")
                start_election()
            elif cleader != leader:
                # O líder mudou (raro, mas possível em race conditions)
                print(f"[Node {my_id}] Leader changed from {leader} to {cleader}")
                leader = cleader

        time.sleep(5)
def spread_chose():
    for server in servers:
        if server.id and server.id != my_id:
            url = f"{server.url()}/leader_selected?sleader={leader}"
            try:
                requests.get(url, timeout=2)
            except:
                pass
def start_election():
    global leader
    while True:
        #print("in election")
        leader_selected = False
        for server in servers:
            if server.id and server.id > my_id:
                url = f"{server.url()}/leader"
                #print(url)
                
                try:
                    result = requests.get(url, timeout=2)
                    leader = int(result.text.strip('"'))
                    leader_selected = True
                    spread_chose()
                    return
                except:
                    pass
        if not leader_selected:
            leader = my_id
            #print(f"I am the leader now: {leader}")
            spread_chose()
            return
        time.sleep(0.5)
@app.get("/kill")
def kill():
    import os
    os._exit(1)
    
# Iniciar thread de verificação de líder
print(f"[Node {my_id}] Starting up...")
threading.Thread(target=check_leader, daemon=True).start()

