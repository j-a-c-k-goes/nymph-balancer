# balancer: main load balancer logic

import std/[net, os]
import ../config/config
import ../logging/logger
import backend_pool

const
  VERSION = "0.1.0"

var
  cfg: BalancerConfig     # global configuration
  pool: BackendPool       # backend server pool

proc forward_data(client: Socket, backend: Socket) =
  ## forward data from client to backend and back
  log_debug("forward", "starting forwarding")
  
  var buffer: array[4096, char]  # data transfer buffer
  
  try:
    # read from client with error handling
    let bytes_read = client.recv(addr buffer[0], 4096)
    if bytes_read <= 0:
      log_info("forward", "client disconnected")
      return
    
    log_debug("forward", "received " & $bytes_read & " bytes from client")
    
    # send to backend with error handling
    try:
      discard backend.send(addr buffer[0], bytes_read)
      log_debug("forward", "forwarded to backend")
    except:
      log_error("forward", "failed to send to backend: " & getCurrentExceptionMsg())
      return
    
    # read response from backend with error handling
    let bytes_from_backend = backend.recv(addr buffer[0], 4096)
    if bytes_from_backend <= 0:
      log_warn("forward", "backend disconnected during response")
      return
    
    log_debug("forward", "received " & $bytes_from_backend & " bytes from backend")
    
    # send back to client with error handling
    try:
      discard client.send(addr buffer[0], bytes_from_backend)
      log_debug("forward", "sent response to client")
    except:
      log_error("forward", "failed to send to client: " & getCurrentExceptionMsg())
      return
    
  except:
    log_error("forward", "unexpected error: " & getCurrentExceptionMsg())

proc handle_connection(client: Socket) =
  ## handle single client connection by forwarding to backend
  log_info("connection", "new client connected")
  
  # get next backend from pool (round-robin)
  let backend_info = pool.get_next_backend()
  
  # connect to backend
  var backend = newSocket()
  try:
    # set timeouts
    backend.setSockOpt(OptReuseAddr, true)
    
    # attempt connection with timeout handling
    try:
      backend.connect(backend_info.host, Port(backend_info.port), timeout = cfg.connect_timeout)
      log_info("connection", "connected to backend " & backend_info.host & ":" & $backend_info.port)
    except TimeoutError:
      log_error("connection", "backend connection timeout after " & $cfg.connect_timeout & "ms")
      client.close()
      backend.close()
      return
    except OSError:
      log_error("connection", "backend unreachable: " & backend_info.host & ":" & $backend_info.port)
      client.close()
      backend.close()
      return
    
    # forward data between client and backend
    forward_data(client, backend)
    
  except:
    log_error("connection", "unexpected error: " & getCurrentExceptionMsg())
  finally:
    backend.close()
    client.close()
    log_info("connection", "connection closed")

proc start_balancer() =
  ## start load balancer and accept connections
  init_logger()
  cfg = load_config()
  
  # initialize backend pool
  pool = init_backend_pool()
  for backend in cfg.backends:
    pool.add_backend(backend.host, backend.port)
  
  log_info("balancer", "nymph-balancer v" & VERSION)
  log_info("balancer", "starting round-robin load balancer")
  log_info("balancer", "backend pool: " & $pool.backend_count() & " servers")
  
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
