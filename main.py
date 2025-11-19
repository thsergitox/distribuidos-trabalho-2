import random
from fastapi import FastAPI
from pydantic import BaseModel
import threading
import time
import requests
import os
from server import Server
from lamport_clock import LamportClock
import server


app = FastAPI()

# Obtener NODE_ID desde variable de entorno
NODE_ID_ENV = os.getenv("NODE_ID")
my_id = int(NODE_ID_ENV) if NODE_ID_ENV else None

# Inicializar Reloj Lógico de Lamport
lamport_clock = LamportClock()

# Configurar lista de servidores basado en el entorno
# En Docker, los nodos se llaman node1, node2, node3
# En local, usar localhost
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
    Modelo de mensaje con soporte para Reloj Lógico de Lamport

    Attributes:
        id: ID único del mensaje (incremental)
        content: Contenido del mensaje
        lamport_timestamp: Timestamp lógico de Lamport
        node_id: ID del nodo que creó el mensaje
        physical_timestamp: Timestamp físico (time.time()) para debugging
    """
    id: int
    content: str
    lamport_timestamp: int
    node_id: int
    physical_timestamp: float


messages = [
    # Mensaje inicial con timestamp Lamport = 0
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
    Obtiene el objeto Server del líder actual

    Returns:
        Server: Objeto del líder, o None si no hay líder o si YO soy el líder
    """
    global leader
    if leader is None:
        print(f"[Node {my_id}] leader_server(): leader is None")
        return None

    # Si YO soy el líder, no tengo que buscar en la lista
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
    Endpoint para crear un nuevo mensaje

    Flujo:
    1. Si no soy líder → reenviar al líder
    2. Si soy líder → crear mensaje y replicar a followers

    Args:
        message: Contenido del mensaje

    Returns:
        int: ID del mensaje creado (solo líder)
        dict: Respuesta del líder (si forwarded)
        dict: Error si no hay líder disponible
    """
    print(f"[Node {my_id}] Received POST request, message='{message}', leader={leader}")

    # PASO 1: Verificar si soy el líder
    if leader != my_id:
        print(f"[Node {my_id}] I'm not the leader ({leader}), forwarding...")
        leader_srv = leader_server()

        if leader_srv is None:
            print(f"[Node {my_id}] ERROR: No leader available!")
            return {"error": "No leader available"}, 503

        # Forward al líder
        url = f"{leader_srv.url()}/?message={message}"
        try:
            response = requests.post(url, json={"message": message}, timeout=2)
            print(f"[Node {my_id}] Forwarded to leader, response: {response.status_code}")
            return response.json()
        except Exception as e:
            print(f"[Node {my_id}] ERROR: Leader not reachable: {e}")
            return {"error": "Leader not reachable"}, 503

    # PASO 2: Soy el líder, crear mensaje
    global messages

    # IMPORTANTE: Incrementar reloj Lamport ANTES de crear el mensaje
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

    # PASO 3: Replicar a todos los followers
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
    Endpoint para recibir mensajes replicados desde el líder

    Flujo:
    1. Actualizar reloj Lamport con max(local, remote) + 1
    2. Guardar mensaje
    3. Ordenar mensajes por timestamp Lamport

    Args:
        message: Mensaje replicado con todos los campos Lamport

    Returns:
        dict: Status y timestamp Lamport local actualizado
    """
    global messages, last_id

    # PASO 1: Actualizar reloj Lamport
    local_lamport = lamport_clock.update(message.lamport_timestamp)

    print(f"[Node {my_id}] Received message {message.id} from leader, "
          f"Lamport: remote={message.lamport_timestamp}, local={local_lamport}")

    # PASO 2: Guardar mensaje
    messages.append(message)
    last_id = max(msg.id for msg in messages)

    # PASO 3: Ordenar mensajes por Lamport (desempate por node_id)
    messages.sort(key=lambda m: (m.lamport_timestamp, m.node_id))

    return {
        "status": "ok",
        "local_lamport": local_lamport
    }
@app.get("/state")
async def state():
    """Retorna estado del nodo (ID, líder actual)"""
    return str(my_id) + " " + str(leader) + str(leader_server())


@app.get("/lamport_time")
async def get_lamport_time():
    """
    Retorna el timestamp Lamport actual del nodo

    Returns:
        dict: Tiempo Lamport actual
    """
    return {"time": lamport_clock.get_time(), "node_id": my_id}


@app.get("/messages")
async def get_all_messages():
    """
    Retorna todos los mensajes ordenados por timestamp Lamport

    Returns:
        list: Lista de mensajes ordenados causalmente
    """
    # Ordenar por Lamport (ya deberían estar ordenados, pero por seguridad)
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
    Thread que verifica continuamente el estado del líder

    Responsabilidades:
    1. Verificar cada 5 segundos si el líder está vivo
    2. Iniciar elección si el líder cae
    3. Actualizar variable global 'leader' si detecta cambio
    """
    global leader
    print(f"[Node {my_id}] Starting leader health check (current leader: {leader})")

    while True:
        # Si YO soy el líder, no necesito hacer health check
        if leader == my_id:
            time.sleep(5)
            continue

        lserver = leader_server()

        # Caso 1: No tenemos líder registrado
        if lserver is None and leader is None:
            print(f"[Node {my_id}] No leader, starting election")
            start_election()
        elif lserver is not None:
            # Caso 2: Tenemos líder, verificar si está vivo
            cleader = lserver.current_leader()

            if cleader is None:
                # El líder no responde, iniciar elección
                print(f"[Node {my_id}] Leader {leader} not responding, starting election")
                start_election()
            elif cleader != leader:
                # El líder cambió (raro, pero posible en race conditions)
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
    
# Iniciar thread de verificación de líder
print(f"[Node {my_id}] Starting up...")
threading.Thread(target=check_leader, daemon=True).start()

