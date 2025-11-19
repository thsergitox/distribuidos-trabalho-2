import uuid
import requests
ports = [
    i for i in range(8000, 8100)
]

for port in ports:
    try:
        url = f"http://localhost:{port}/state"
        response = requests.get(url, timeout=2)
        if response.status_code == 200:
            print(f"{port}: {response.text}")
    except Exception as e:
        pass