## load_test: send multiple requests to test round-robin

import ../src/core/winsock_raw
import std/[strutils, times]
import os

proc send_request(request_num: int) =
  ## send: single request to balancer
  let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if sock == INVALID_SOCKET:
    echo "[error] failed to create socket"
    return
  
  var server_addr = SockAddrIn(
    family: AF_INET.cushort,
    port: htons(8080),
    address: inet_addr("127.0.0.1")
  )
  
  if connect(sock, addr server_addr, sizeof(SockAddrIn).cint) == SOCKET_ERROR:
    echo "[error] connection failed"
    discard closesocket(sock)
    return
  
  let message = "test" & $request_num
  discard send(sock, unsafeAddr message[0], message.len.cint, 0)
  
  var buffer: array[1024, char]
  let recv_len = recv(sock, addr buffer[0], 1024, 0)
  
  if recv_len > 0:
    let response = newString(recv_len)
    copyMem(unsafeAddr response[0], addr buffer[0], recv_len)
    echo "[request ", request_num, "] response: ", response
  else:
    echo "[request ", request_num, "] no response"
  
  discard closesocket(sock)

when isMainModule:
  if not init_winsock():
    echo "[error] winsock init failed"
    quit(1)
  
  echo "[load_test] sending 10 requests..."
  
  for request_index in 1..10:
    send_request(request_index)
    sleep(100)
  
  cleanup_winsock()
  echo "[load_test] complete"
