import winsock_raw, backend_pool
import ../logging/logger
import std/[locks, os, times]

const
  HEALTH_CHECK_INTERVAL = 5000    # check every 5 seconds
  HEALTH_CHECK_TIMEOUT = 2000     # 2 second timeout per check

type
  HealthCheckerContext = object
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
  log_info("health", "health checker thread entry")
  let ctx = cast[ptr HealthCheckerContext](arg)
  log_info("health", "context cast complete")
  
  if ctx.isNil:
    log_error("health", "context is nil")
    return
  
  log_info("health", "checking running flag")
  if ctx.running.isNil:
    log_error("health", "running pointer is nil")
    return
  
  log_info("health", "health checker started, running=" & $ctx.running[])
  
  while ctx.running[]:
    log_info("health", "health check cycle starting")
    acquire(ctx.pool.lock)
    let backend_count = ctx.pool.backends.len
    release(ctx.pool.lock)
    log_info("health", "checking " & $backend_count & " backends")
    
    for backend_index in 0..<backend_count:
      acquire(ctx.pool.lock)
      let backend = ctx.pool.backends[backend_index]
      release(ctx.pool.lock)
      
      let is_alive = probe_backend(backend.host, backend.port)
      
      if is_alive != backend.alive:
        acquire(ctx.pool.lock)
        ctx.pool.backends[backend_index].alive = is_alive
        release(ctx.pool.lock)
        
        if is_alive:
          log_info("health", backend.host & ":" & $backend.port & " is now alive")
        else:
          log_warn("health", backend.host & ":" & $backend.port & " is now dead")
    
    sleep(ctx.check_interval)

proc start_health_checker*(pool: ptr BackendPool, running: ptr bool): Thread[pointer] =
  ## start: launch health checker thread
  log_info("health", "allocating context")
  var ctx = cast[ptr HealthCheckerContext](alloc0(sizeof(HealthCheckerContext)))
  log_info("health", "setting pool pointer")
  ctx.pool = pool
  log_info("health", "setting running pointer")
  ctx.running = running
  log_info("health", "setting check interval")
  ctx.check_interval = HEALTH_CHECK_INTERVAL
  
  log_info("health", "creating thread")
  var thread: Thread[pointer]
  createThread(thread, health_check_thread, ctx)
  log_info("health", "thread created successfully")
  return thread
