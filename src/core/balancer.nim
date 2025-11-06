# balancer: main load balancer logic

import std/[net, os]
import ../config/config
import ../logging/logger

const
  VERSION = "0.1.0"

var
  cfg: BalancerConfig

proc forward_data(client: Socket, backend: Socket) =
  ## forward data from client to backend and back
  log_debug("forward", "starting forwarding")
  
  var buffer: array[4096, char]
  
  try:
    # read from client
    let bytes_read = client.recv(addr buffer[0], 4096)
    if bytes_read <= 0:
      log_info("forward", "client disconnected")
      return
    
    log_debug("forward", "received " & $bytes_read & " bytes from client")
    
    # send to backend
    discard backend.send(addr buffer[0], bytes_read)
    log_debug("forward", "forwarded to backend")
    
    # read response from backend
    let bytes_from_backend = backend.recv(addr buffer[0], 4096)
    if bytes_from_backend <= 0:
      log_warn("forward", "backend disconnected")
      return
    
    log_debug("forward", "received " & $bytes_from_backend & " bytes from backend")
    
    # send back to client
    discard client.send(addr buffer[0], bytes_from_backend)
    log_debug("forward", "sent response to client")
    
  except:
    log_error("forward", "error: " & getCurrentExceptionMsg())

proc handle_connection(client: Socket) =
  ## handle single client connection by forwarding to backend
  log_info("connection", "new client connected")
  
  # connect to backend
  var backend = newSocket()
  try:
    backend.connect(cfg.backend_host, Port(cfg.backend_port))
    log_info("connection", "connected to backend " & cfg.backend_host & ":" & $cfg.backend_port)
    
    # forward data between client and backend
    forward_data(client, backend)
    
  except:
    log_error("connection", "failed to connect to backend: " & getCurrentExceptionMsg())
  finally:
    backend.close()
    client.close()
    log_info("connection", "connection closed")

proc start_balancer() =
  ## start load balancer and accept connections
  init_logger()
  cfg = load_config()
  
  log_info("balancer", "nymph-balancer v" & VERSION)
  log_info("balancer", "starting tcp proxy")
  
  var server = newSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(cfg.listen_port), cfg.listen_host)
  server.listen()
  
  log_info("balancer", "listening on " & cfg.listen_host & ":" & $cfg.listen_port)
  log_info("balancer", "waiting for connections...")
  echo ""
  
  while true:
    var client: Socket
    server.accept(client)
    
    # handle connection (blocking for phase-a.1)
    # will be threaded in phase-b
    handle_connection(client)

when isMainModule:
  start_balancer()
