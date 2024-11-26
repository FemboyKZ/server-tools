import sys
import valve.source.a2s

def query_server(address, port):
    try:
        with valve.source.a2s.ServerQuerier((address, int(port))) as server:
            info = server.info()
            players = server.players()
            status = {
                "server": f"{address}:{port}",
                "status": "EMPTY" if len(players) == 0 else "ACTIVE",
                "players": f"{len(players)}/{info['max_players']}",
                "map": info['map'],
                "name": info['server_name'],
            }
            return status
    except valve.source.NoResponseError:
        return {"server": f"{address}:{port}", "status": "OFFLINE"}

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: query_server.py <address> <port>")
        sys.exit(1)
    server_address = sys.argv[1]
    server_port = sys.argv[2]
    result = query_server(server_address, server_port)
    print(result)
