# phase-b: round-robin load balancing

## overview

phase-b implements round-robin load balancing across multiple backend servers.

## milestones

- [x] **b.1**: backend_pool module (add/remove backends)
  - Backend type with host, port, alive status
  - BackendPool type with seq of backends
  - thread-safe with locks
  - add_backend() to register servers
  - backend_count() for pool size

- [x] **b.2**: round-robin algorithm implementation
  - get_next_backend() cycles through backends
  - current_index tracks position
  - modulo arithmetic for wraparound
  - thread-safe access with locks

- [x] **b.3**: distribute connections across 3+ backends
  - config.yaml supports multiple backends
  - config parser handles backend list
  - balancer initializes pool from config
  - each connection gets next backend in rotation
  - backend response includes port number for verification

- [ ] **b.4**: benchmark: measure req/sec vs single backend
  - create benchmark tool
  - measure throughput with 1 backend
  - measure throughput with 3 backends
  - compare performance

## current implementation

### backend_pool.nim
- Backend type: host, port, alive flag
- BackendPool: seq of backends, current_index, lock
- round-robin selection with modulo wraparound
- thread-safe operations

### config.nim updates
- BackendConfig type for backend entries
- backends field as seq[BackendConfig]
- parses yaml list format (- host: / port:)
- displays all configured backends on load

### balancer.nim updates
- imports backend_pool module
- global pool variable
- initializes pool from config
- get_next_backend() for each connection
- logs backend selection

### simple_backend.nim updates
- accepts port as command line argument
- includes port number in response
- allows running multiple instances

## testing phase-b

```bash
# terminal 1-3: start backends
bin\simple_backend.exe 9000
bin\simple_backend.exe 9001
bin\simple_backend.exe 9002

# terminal 4: start balancer
bin\nymph_balancer.exe

# terminal 5+: test with telnet
telnet localhost 8080
# send data, observe which backend responds
# repeat to verify round-robin distribution
```

## round-robin algorithm

```
backends: [A, B, C]
current_index: 0

connection 1 -> backend A (index 0), index = 1
connection 2 -> backend B (index 1), index = 2
connection 3 -> backend C (index 2), index = 0
connection 4 -> backend A (index 0), index = 1
...
```

## known limitations

- blocking implementation (one connection at a time)
- no health checks (all backends assumed alive)
- no performance measurement yet
- no concurrent connection handling

these will be addressed in subsequent phases.

## next steps

- test b.1-b.3 implementation
- create benchmark tool for b.4
- measure performance improvement
