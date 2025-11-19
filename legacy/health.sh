ports=(8000 8001 8002 8083)
for port in "${ports[@]}"; do
     echo -n "Server $port: " 
     url="http://localhost:$port/state"
     curl -s "$url"
     echo ""
done