# backend_pool: manage multiple backend servers

import std/locks

type
  Backend* = object
    host*: string           # backend server address
    port*: int              # backend server port
    alive*: bool            # whether backend is reachable
  
  BackendPool* = object
    backends*: seq[Backend] # list of backend servers
    current_index: int      # current position for round-robin
    lock: Lock              # thread-safe access

proc init_backend_pool*(): BackendPool =
  ## initialize empty backend pool
  result.backends      = @[]
  result.current_index = 0
  initLock(result.lock)

proc add_backend*(pool: var BackendPool, host: string, port: int) =
  ## add backend to pool
  pool.backends.add(Backend(host: host, port: port, alive: true))

proc get_next_backend*(pool: var BackendPool): Backend =
  ## get next backend using round-robin algorithm
  acquire(pool.lock)
  defer: release(pool.lock)
  if pool.backends.len == 0:
    raise newException(ValueError, "no backends available")
  # round-robin: cycle through backends
  let backend        = pool.backends[pool.current_index]
  let selected_index = pool.current_index
  pool.current_index = (pool.current_index + 1) mod pool.backends.len
  echo "[pool] selected backend index: ", selected_index, " -> ", backend.host, ":", backend.port, " (next: ", pool.current_index, ")"
  return backend

proc backend_count*(pool: BackendPool): int =
  ## return number of backends in pool
  return pool.backends.len