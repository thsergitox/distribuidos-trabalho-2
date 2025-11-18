from typing import Union
from fastapi import FastAPI
from pydantic import BaseModel
import uuid
import threading
import time
import requests
import server
my_uuid = uuid.uuid4()


class Server(BaseModel):
    host: str
    port: int
    id: int
    
    def url(self):
        return f"http://{self.host}:{self.port}"
         
    def current_leader(self):
        try:
            response = requests.get(self.url() + "/leader", timeout=2)
            if response.status_code == 200:
                return uuid.UUID(response.text.strip('"'))
            return None
        except:
            return None