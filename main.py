import random
from fastapi import FastAPI
from pydantic import BaseModel
import threading
import time
import requests
from server import Server 
import server


app = FastAPI()
my_id = None
servers = [
    Server(
        host="172.17.0.1", 
        port=i, 
        id=i
    )
    for i in range(8001, 8100)
]
class Message(BaseModel):
    id: int
    content: str
messages = [
    Message(id=1, content="Hello"),
]

leader = None 
last_id = 1
def leader_server():
    global leader
    if leader is None:
        return None
    for server in servers:
        if server.id == leader:
            return server
    return None
@app.get("/")
async def get(id : int ):
    return next((msg for msg in messages if msg.id == id), None)

@app.post("/set_id")
async def set_id(id: int):
    global my_id
    my_id = id
    return {"status": "ok"}
@app.get("/say_ids")
async def say_ids():
    for server in servers:
        if server.id and server.id != my_id:
            url = f"{server.url()}/set_id?id={server.port}"
            try:
                requests.get(url, timeout=2)
            except Exception as e:
                pass
@app.post("/")
async def post(message: str):
    if leader != my_id:
        leader_srv = leader_server()
        if leader_srv is None:
            return {"error": "No leader available"}, 503
        url = f"{leader_srv.url()}/?message={message}"
        try:
            response = requests.post(url, json={"message": message}, timeout=2)
            return response.json()
        except Exception as e:
            return {"error": "Leader not reachable"}, 503
    
    global messages
    id = max(msg.id for msg in messages) + 1
    messages.append(Message(
        id=id,
        content=message
    ))
    for server in servers:
        if server.id and server.id != my_id:
            url = f"{server.url()}/message_received"
            try:
                result = requests.post(url, json={"content": message, "id": id}, timeout=2)
                print(f"Sent message {id} to server {server.id}: {result.content}")
            except Exception as e:
                print(f"Error sending message to server {server.id}: {e}")
                pass
    return id  

@app.post("/message_received")
async def message_received(message: Message):
    global messages, last_id
    print(f"Received message {message.id} from leader")
    messages.append(message)
    last_id = max(msg.id for msg in messages)
    return {"status": "ok"}
@app.get("/state")
async def state():
    return str(my_id) + " " + str(leader)   + str(leader_server())
            

@app.get("/leader")
def get_leader():
    return leader 

@app.get("/leader_selected")
def leader_selected(sleader = int):
    global leader
    print(f"Leader selected: {sleader}")
    leader = sleader


def check_leader():
    global leader
    print(leader)
    while True:
        lserver = leader_server()
        if lserver is None:
            print("No leader, starting election")
            start_election()
        else:
            cleader = lserver.current_leader()
            if cleader is None:
                print("Leader not responding, starting election")
                start_election()
            if cleader != leader:
                print(f"Leader changed from {leader} to {cleader}")
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
    
def ask_my_id():
    global my_id
    time.sleep(random.uniform(0,5))
    while my_id is None:
        for server in servers:
            if server.id and server.id != my_id:
                url = f"{server.url()}/say_ids"
                try:
                    my_id =requests.get(url, timeout=2)
                except Exception as e:
                    pass
        time.sleep(random.uniform(0,1))
threading.Thread(target=ask_my_id, daemon=True).start()
threading.Thread(target=check_leader, daemon=True).start()

