# balancer_worker_pool: manage load balancer worker pool

import winsock_raw, backend_pool, connection_queue, health_checker
import ../logging/logger
import std/[locks, times, os]

const
  WORKER_COUNT   = 4     # number of worker threads
  QUEUE_CAPACITY = 1024  # max queued connections
  BUFFER_SIZE    = 8192  # tcp buffer size

type
  BalancerState* = object
    server_socket: WinSocket           # listening socket
    connection_queue: ConnectionQueue  # pending connections
    backend_pool: ptr BackendPool      # available backends
    running: bool                      # shutdown flag
    stats_lock: Lock                   # stats thread safety
    total_connections: int             # lifetime connection count
    active_connections: int            # currently processing

var global_state: ptr BalancerState

proc handle_connection(conn_data: ConnectionData, backend_pool: ptr BackendPool) {.gcsafe.} =
  ## forward: proxy request to backend and return response
  let client_sock      = conn_data.client_socket
  let request_data     = conn_data.request_data
  let selected_backend = backend_pool[].get_next_backend()
  let backend_sock     = connect_to_backend(selected_backend.host, selected_backend.port)
  
  if backend_sock == INVALID_SOCKET:
    log_error("backend", "failed to connect to " & selected_backend.host & ":" & $selected_backend.port)
    discard closesocket(client_sock)
    return
  log_info("worker", "sending " & $request_data.len & " bytes to backend")
  let send_result = send(backend_sock, unsafeAddr request_data[0], request_data.len.cint, 0)
  
  if send_result == SOCKET_ERROR:
    log_error("backend", "failed to send to backend")
    discard closesocket(backend_sock)
    discard closesocket(client_sock)
    return
  const SD_SEND = 1 # shutdown signal
  discard shutdown(backend_sock, SD_SEND)
  log_info("worker", "sent " & $send_result & " bytes, shutdown send, waiting for response")
  var buffer: array[BUFFER_SIZE, char]
  let backend_recv = recv(backend_sock, addr buffer[0], BUFFER_SIZE, 0)
  log_info("worker", "received " & $backend_recv & " bytes from backend")
  discard closesocket(backend_sock)
  
  if backend_recv <= 0:
    log_warn("worker", "no response from backend")
    discard closesocket(client_sock)
    return
  
  log_info("worker", "sending response to client")
  let client_send = send(client_sock, addr buffer[0], backend_recv, 0)
  log_info("worker", "sent " & $client_send & " bytes to client")
  discard closesocket(client_sock)

proc worker_thread(arg: pointer) {.thread, gcsafe.} =
  ## process: worker thread that handles connections from queue
  let state = cast[ptr BalancerState](arg)
  log_info("worker", "worker thread started")
  
  while state.running:
    let result = state.connection_queue.dequeue()
    if result.success:
      acquire(state.stats_lock)
      inc state.active_connections
      release(state.stats_lock)
      handle_connection(result.data, state.backend_pool)
      acquire(state.stats_lock)
      dec state.active_connections
      release(state.stats_lock)
    else:
      sleep(1)

proc acceptor_thread(arg: pointer) {.thread, gcsafe.} =
  ## accept: acceptor thread that accepts connections and reads data immediately
  let state = cast[ptr BalancerState](arg)
  log_info("acceptor", "acceptor thread started")
  while state.running:
    let client_sock = accept_connection(state.server_socket)
    if client_sock != INVALID_SOCKET:
      log_info("acceptor", "accepted connection")
      var buffer: array[BUFFER_SIZE, char]
      let recv_len = recv(client_sock, addr buffer[0], BUFFER_SIZE, 0)
      if recv_len > 0:
        var request_data = newString(recv_len)
        copyMem(addr request_data[0], addr buffer[0], recv_len)
        let conn_data = ConnectionData(
          client_socket: client_sock,
          request_data:  request_data,
          timestamp:     epochTime()
        )
        if not state.connection_queue.enqueue(conn_data):
          log_warn("acceptor", "queue full, dropping connection")
          discard closesocket(client_sock)
        else:
          acquire(state.stats_lock)
          inc state.total_connections
          release(state.stats_lock)
          log_info("acceptor", "data read and enqueued")
      else:
        log_warn("acceptor", "no data from client")
        discard closesocket(client_sock)

proc start_balancer*(listen_port: int, backend_pool: var BackendPool) =
  ## run: start balancer with worker pool architecture
  if not init_winsock():
    log_error("balancer", "failed to initialize winsock")
    return
  global_state                  = cast[ptr BalancerState](alloc0(sizeof(BalancerState)))
  global_state.server_socket    = create_server_socket(listen_port)
  global_state.connection_queue = init_connection_queue(QUEUE_CAPACITY)
  global_state.backend_pool     = addr backend_pool
  global_state.running          = true
  initLock(global_state.stats_lock)
  log_info("balancer", "starting on port " & $listen_port)
  log_info("balancer", "worker threads: " & $WORKER_COUNT)
  log_info("balancer", "queue capacity: " & $QUEUE_CAPACITY)
  
  var health_thread = start_health_checker(global_state.backend_pool, addr global_state.running)
  log_info("balancer", "health checker started")
  
  var acceptor: Thread[pointer]
  createThread(acceptor, acceptor_thread, global_state)
  var workers: array[WORKER_COUNT, Thread[pointer]]
  for worker_index in 0..<WORKER_COUNT:
    createThread(workers[worker_index], worker_thread, global_state)
  log_info("balancer", "all threads started, balancer running")
  while global_state.running:
    sleep(5000)
    acquire(global_state.stats_lock)
    let total  = global_state.total_connections
    let active = global_state.active_connections
    let queued = global_state.connection_queue.get_count()
    release(global_state.stats_lock)
    log_info("stats", "total: " & $total & " | active: " & $active & " | queued: " & $queued)
  joinThread(acceptor)
  for worker_index in 0..<WORKER_COUNT:
    joinThreads(workers[worker_index])
  joinThread(health_thread)
  discard closesocket(global_state.server_socket)
  cleanup_winsock()
  dealloc(global_state)