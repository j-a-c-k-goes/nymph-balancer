# simple_backend: minimal tcp server for testing

import std/net

import std/[os, strutils]

var
  backend_port = 9000     # default port

proc parse_args() =
  ## parse command line arguments for port
  if paramCount() > 0:
    try:
      backend_port = parseInt(paramStr(1))
    except:
      echo "invalid port, using default: ", backend_port

proc handle_client(client: Socket) =
  ## handle client connection with simple echo response
  echo "[backend] client connected"
  
  var buffer: array[4096, char]
  try:
    # read once and respond (no loop)
    let bytes_read = client.recv(addr buffer[0], 4096)
    if bytes_read > 0:
      # convert buffer to string
      var data = newString(bytes_read)
      for index in 0..<bytes_read:
        data[index] = buffer[index]
      
      echo "[backend] received: ", data
      
      # echo back with prefix including port number
      let response = "backend_" & $backend_port & ": " & data
      discard client.send(response.cstring, response.len)
      echo "[backend] sent response"
    else:
      echo "[backend] no data received"
      
  except:
    echo "[backend] error: ", getCurrentExceptionMsg()
  finally:
    client.close()
    echo "[backend] client disconnected"

proc start_backend() =
  ## start simple backend server
  parse_args()
  
  echo "simple backend server"
  echo "listening on port ", backend_port
  echo ""
  
  var server = newSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(backend_port))
  server.listen()
  
  echo "ready to accept connections"
  echo ""
  
  while true:
    var client: Socket
    server.accept(client)
    handle_client(client)

when isMainModule:
  start_backend()
