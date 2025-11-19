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
        """Retorna a URL completa do servidor"""
        return f"http://{self.host}:{self.port}"

    def current_leader(self):
        """
        Consulta quem é o líder atual segundo este servidor

        Returns:
            int: ID do líder, ou None se não responde
        """
        try:
            response = requests.get(self.url() + "/leader", timeout=2)
            if response.status_code == 200:
                # O líder retorna seu ID como int
                leader_id = response.text.strip('"')
                return int(leader_id) if leader_id != 'null' else None
            return None
        except:
            return None