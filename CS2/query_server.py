import sys
import a2s
import json

def query_server(address, port):
    try:
        info = a2s.info((address, int(port)))
        players = a2s.players((address, int(port)))
        result = {
            "server": f"{address}:{port}",
            "status": "EMPTY" if len(players) == 0 else "ACTIVE",
            "players": f"{len(players)}/{info.max_players}",
            "map": info.map_name,
            "name": info.server_name
        }
    except Exception as e:
        result = {"server": f"{address}:{port}", "status": "OFFLINE", "error": str(e)}

    print(json.dumps(result))

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: query_server.py <address> <port>")
        sys.exit(1)
    server_address = sys.argv[1]
    server_port = sys.argv[2]
    query_server(server_address, server_port)
