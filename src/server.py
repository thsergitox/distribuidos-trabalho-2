from typing import Union
from fastapi import FastAPI
from pydantic import BaseModel
import threading
import time
import requests


class Server(BaseModel):
    host: str
    port: int
    id: int

    def url(self):
        """Retorna la URL completa del servidor"""
        return f"http://{self.host}:{self.port}"

    def current_leader(self):
        """
        Consulta quién es el líder actual según este servidor

        Returns:
            int: ID del líder, o None si no responde
        """
        try:
            response = requests.get(self.url() + "/leader", timeout=2)
            if response.status_code == 200:
                # El líder retorna su ID como int
                leader_id = response.text.strip('"')
                return int(leader_id) if leader_id != 'null' else None
            return None
        except:
            return None