## test_backend_direct: test backend directly without balancer

import ../src/core/winsock_raw

when isMainModule:
  if not init_winsock():
    echo "[error] winsock init failed"
    quit(1)
  
  echo "[test] connecting to backend 9000..."
  let sock = connect_to_backend("127.0.0.1", 9000)
  if sock == INVALID_SOCKET:
    echo "[error] connection failed"
    cleanup_winsock()
    quit(1)
  
  echo "[test] connected, sending data..."
  let message = "test"
  let send_result = send(sock, unsafeAddr message[0], message.len.cint, 0)
  echo "[test] sent ", send_result, " bytes"
  
  echo "[test] waiting for response..."
  var buffer: array[1024, char]
  let recv_len = recv(sock, addr buffer[0], 1024, 0)
  echo "[test] received ", recv_len, " bytes"
  
  if recv_len > 0:
    var response = newString(recv_len)
    copyMem(addr response[0], addr buffer[0], recv_len)
    echo "[test] response: ", response
  
  discard closesocket(sock)
  cleanup_winsock()
