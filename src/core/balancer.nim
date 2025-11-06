# balancer: main load balancer logic

import std/[net, os]
import ../config/config

const
  VERSION = "0.1.0"

var
  cfg: BalancerConfig

proc forward_data(client: Socket, backend: Socket) =
  ## forward data from client to backend and back
  echo "[forward_data] starting forwarding"
  
  var buffer: array[4096, char]
  
  try:
    # read from client
    let bytes_read = client.recv(addr buffer[0], 4096)
    if bytes_read <= 0:
      echo "[forward_data] client disconnected"
      return
    
    echo "[forward_data] received ", bytes_read, " bytes from client"
    
    # send to backend
    discard backend.send(addr buffer[0], bytes_read)
    echo "[forward_data] forwarded to backend"
    
    # read response from backend
    let bytes_from_backend = backend.recv(addr buffer[0], 4096)
    if bytes_from_backend <= 0:
      echo "[forward_data] backend disconnected"
      return
    
    echo "[forward_data] received ", bytes_from_backend, " bytes from backend"
    
    # send back to client
    discard client.send(addr buffer[0], bytes_from_backend)
    echo "[forward_data] sent response to client"
    
  except:
    echo "[forward_data] error: ", getCurrentExceptionMsg()

proc handle_connection(client: Socket) =
  ## handle single client connection by forwarding to backend
  echo "[handle_connection] new client connected"
  
  # connect to backend
  var backend = newSocket()
  try:
    backend.connect(cfg.backend_host, Port(cfg.backend_port))
    echo "[handle_connection] connected to backend ", cfg.backend_host, ":", cfg.backend_port
    
    # forward data between client and backend
    forward_data(client, backend)
    
  except:
    echo "[handle_connection] failed to connect to backend: ", getCurrentExceptionMsg()
  finally:
    backend.close()
    client.close()
    echo "[handle_connection] connection closed"

proc start_balancer() =
  ## start load balancer and accept connections
  cfg = load_config()
  echo ""
  echo "nymph-balancer v", VERSION
  echo "starting tcp proxy"
  echo ""
  
  var server = newSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(cfg.listen_port), cfg.listen_host)
  server.listen()
  
  echo "listening on ", cfg.listen_host, ":", cfg.listen_port
  echo "waiting for connections..."
  echo ""
  
  while true:
    var client: Socket
    server.accept(client)
    
    # handle connection (blocking for phase-a.1)
    # will be threaded in phase-b
    handle_connection(client)

when isMainModule:
  start_balancer()
