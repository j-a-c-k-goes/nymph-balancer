# simple_backend: minimal tcp server for testing

import std/net

const
  BACKEND_PORT = 9000

proc handle_client(client: Socket) =
  ## handle client connection with simple echo response
  echo "[backend] client connected"
  
  var buffer: array[4096, char]
  try:
    while true:
      let bytes_read = client.recv(addr buffer[0], 4096)
      if bytes_read <= 0:
        break
      
      # convert buffer to string
      var data = newString(bytes_read)
      for index in 0..<bytes_read:
        data[index] = buffer[index]
      
      echo "[backend] received: ", data
      
      # echo back with prefix
      let response = "backend_response: " & data
      discard client.send(response.cstring, response.len)
      
  except:
    echo "[backend] error: ", getCurrentExceptionMsg()
  finally:
    client.close()
    echo "[backend] client disconnected"

proc start_backend() =
  ## start simple backend server
  echo "simple backend server"
  echo "listening on port ", BACKEND_PORT
  echo ""
  
  var server = newSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(BACKEND_PORT))
  server.listen()
  
  echo "ready to accept connections"
  echo ""
  
  while true:
    var client: Socket
    server.accept(client)
    handle_client(client)

when isMainModule:
  start_backend()
