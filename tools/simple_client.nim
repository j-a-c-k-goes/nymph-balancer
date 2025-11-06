# simple_client: test client for balancer

import std/[net, os]

const
  BALANCER_HOST = "127.0.0.1"
  BALANCER_PORT = 8080

proc test_connection() =
  echo "connecting to balancer at ", BALANCER_HOST, ":", BALANCER_PORT
  
  var client = newSocket()
  try:
    client.connect(BALANCER_HOST, Port(BALANCER_PORT))
    echo "connected successfully"
    
    # send test message
    let message = "hello from client\n"
    echo "sending: ", message
    discard client.send(message.cstring, message.len)
    
    # receive response
    var buffer: array[4096, char]
    let bytes_read = client.recv(addr buffer[0], 4096)
    
    if bytes_read > 0:
      var response = newString(bytes_read)
      for index in 0..<bytes_read:
        response[index] = buffer[index]
      echo "received: ", response
    else:
      echo "no response received"
    
  except:
    echo "error: ", getCurrentExceptionMsg()
  finally:
    client.close()
    echo "connection closed"

when isMainModule:
  test_connection()
