# connection_queue: model implementatio of connection ring

import locks, winsock_raw
import ../logging/logger

type
  ConnectionData* = object
    client_socket*: WinSocket       # client socket handle
    request_data*: string           # data read from client
    timestamp*: float               # connection accept time

  ConnectionQueue* = object
    buffer: seq[ConnectionData]     # ring buffer storage
    capacity: int                   # maximum queue size
    head: int                       # read position
    tail: int                       # write position
    count: int                      # current items in queue
    lock: Lock                      # thread safety
    not_empty: Cond                 # signal for dequeue
    not_full: Cond                  # signal for enqueue

proc init_connection_queue*(capacity: int): ConnectionQueue =
  ## create: initialize ring buffer queue with given capacity
  result.buffer   = newSeq[ConnectionData](capacity)
  result.capacity = capacity
  result.head     = 0
  result.tail     = 0
  result.count    = 0
  initLock(result.lock)
  initCond(result.not_empty)
  initCond(result.not_full)

proc enqueue*(queue: var ConnectionQueue, conn: ConnectionData): bool =
  ## add: insert connection into queue, return false if full
  acquire(queue.lock)
  defer: release(queue.lock)
  if queue.count >= queue.capacity:
    log_warn("queue", "at capacity. releasing lock.")
    release(queue.lock)
    return false
  queue.buffer[queue.tail] = conn
  queue.tail               = (queue.tail + 1) mod queue.capacity
  inc queue.count
  signal(queue.not_empty)
  return true

proc dequeue*(queue: var ConnectionQueue): tuple[success: bool, data: ConnectionData] =
  ## remove: extract connection from queue, return success flag
  acquire(queue.lock)
  defer: release(queue.lock)
  if queue.count == 0:
    log_warn("queue", "w/o connections. there is nothing to extract..")
    return (false, ConnectionData())
  result.data = queue.buffer[queue.head]
  queue.head  = (queue.head + 1) mod queue.capacity
  dec queue.count
  signal(queue.not_full)
  result.success = true

proc get_count*(queue: var ConnectionQueue): int =
  ## query: return current number of items in queue
  acquire(queue.lock)
  defer: release(queue.lock)
  return queue.count
