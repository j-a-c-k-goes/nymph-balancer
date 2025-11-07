# phase-b restart: worker pool architecture

## what went wrong

**attempted approaches:**
1. nim's net module - blocked after first connection (known windows bug)
2. winsock with blocking sockets - same blocking issue
3. winsock with select() per connection - still sequential, not concurrent

**fundamental error:**
all approaches handled ONE connection at a time. even with non-blocking sockets and select(), the architecture was:
```
accept connection 1 -> handle completely -> accept connection 2 -> handle completely
```

this is WRONG for a load balancer.

## correct architecture (from star-server-7)

**worker pool pattern:**
```
acceptor thread: accept connections -> put in queue
worker threads: pull from queue -> handle concurrently
```

**key components:**
- ring buffer queue (O(1) operations)
- multiple worker threads
- all sockets non-blocking
- no single connection blocks the system

## files kept

**working modules:**
- `src/core/winsock_raw.nim` - raw winsock API (correct)
- `src/core/backend_pool.nim` - round-robin backend selection (correct)
- `src/config/config.nim` - configuration parsing (correct)
- `src/logging/logger.nim` - logging system (correct)

**test tools:**
- `tools/simple_backend.nim` - test backend server
- `tools/quick_test.nim` - test client

## files to create

**new architecture:**
- `src/core/connection_queue.nim` - ring buffer for accepted connections
- `src/core/balancer_worker_pool.nim` - main balancer with worker threads

## implementation plan

1. create ring buffer queue for connections
2. create acceptor thread (accepts, enqueues)
3. create worker threads (dequeue, handle)
4. workers use backend_pool for round-robin
5. all sockets non-blocking
6. proper concurrent handling

## reference

star-server-7 proved this architecture works:
- 3500+ concurrent connections
- 0.06% timeout rate
- 29x improvement over single-threaded

apply same pattern to load balancer.
