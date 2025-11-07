# quick_test: quick round-robin test

import std/[net, os]

proc test_connection(num: int): string =
  ## send single request and get response
  var client = newSocket()
  try:
    echo "  [DEBUG] connecting..."
    client.connect("127.0.0.1", Port(8080), timeout = 5000)
    
    # disable Nagle's algorithm to send small packets immediately
    client.setSockOpt(OptNoDelay, true)
    
    echo "  [DEBUG] connected, sending data..."
    let message = "test" & $num & "\n"
    let sent = client.send(message.cstring, message.len)
    echo "  [DEBUG] sent ", sent, " bytes"
    
    var buffer: array[4096, char]
    let bytes_read = client.recv(addr buffer[0], 4096)
    
    if bytes_read > 0:
      var response = newString(bytes_read)
      for index in 0..<bytes_read:
        response[index] = buffer[index]
      client.close()
      return response
    else:
      client.close()
      return "no response"
  except:
    try:
      client.close()
    except:
      discard
    return "error: " & getCurrentExceptionMsg()

proc main() =
  echo "quick round-robin test"
  echo "sending 6 requests..."
  echo ""
  
  for num in 1..6:
    echo "request ", num, ":"
    let response = test_connection(num)
    echo "  response: ", response
    sleep(100)  # small delay between requests
  
  echo ""
  echo "done - check which backends responded"

when isMainModule:
  main()
