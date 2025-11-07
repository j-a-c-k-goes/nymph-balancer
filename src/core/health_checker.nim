import winsock_raw, backend_pool
import ../logging/logger
import std/[locks, os, times]

const
  HEALTH_CHECK_INTERVAL = 5000    # check every 5 seconds
  HEALTH_CHECK_TIMEOUT = 2000     # 2 second timeout per check

type
  HealthChecker* = object
    pool: ptr BackendPool           # backend pool to monitor
    running: ptr bool               # checker running flag
    check_interval: int             # milliseconds between checks

proc probe_backend(host: string, port: int): bool =
  ## probe: attempt tcp connection to backend
  let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if sock == INVALID_SOCKET:
    return false
  
  var timeout_val: cint = HEALTH_CHECK_TIMEOUT
  discard setsockopt(sock, SOL_SOCKET, 0x1006, addr timeout_val, sizeof(timeout_val).cint)
  
  var backend_addr = SockAddrIn(
    family: AF_INET.cushort,
    port: htons(port.cushort),
    address: inet_addr(host.cstring)
  )
  
  let connect_result = connect(sock, addr backend_addr, sizeof(SockAddrIn).cint)
  discard closesocket(sock)
  
  return connect_result != SOCKET_ERROR

proc health_check_thread(arg: pointer) {.thread, gcsafe.} =
  ## check: periodic health check thread
  let checker = cast[ptr HealthChecker](arg)
  log_info("health", "health checker started")
  
  while checker.running[]:
    for backend_index in 0..<checker.pool.backends.len:
      let backend = checker.pool.backends[backend_index]
      let is_alive = probe_backend(backend.host, backend.port)
      
      if is_alive != backend.alive:
        if is_alive:
          log_info("health", backend.host & ":" & $backend.port & " is now alive")
        else:
          log_warn("health", backend.host & ":" & $backend.port & " is now dead")
        
        checker.pool.backends[backend_index].alive = is_alive
    
    sleep(checker.check_interval)

proc start_health_checker*(pool: ptr BackendPool, running: ptr bool): Thread[pointer] =
  ## start: launch health checker thread
  var checker = cast[ptr HealthChecker](alloc0(sizeof(HealthChecker)))
  checker.pool = pool
  checker.running = running
  checker.check_interval = HEALTH_CHECK_INTERVAL
  
  var thread: Thread[pointer]
  createThread(thread, health_check_thread, checker)
  return thread
