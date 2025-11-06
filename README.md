# nymph-balancer

**layer 4 load balancer implementation experiment**

an experiment in building a tcp load balancer from first principles using nim.

## status

**phase-a: tcp proxy** (complete)  
- [x] a.0: project setup, structure
- [x] a.1: accept single connection, forward to 1 backend
- [x] a.2: add config file parsing (backend address)
- [x] a.3: add basic logging
- [x] a.4: handle connection errors gracefully

## what it does

nymph-balancer distributes incoming tcp connections across multiple backend servers using various load balancing algorithms.

**planned features:**
- round-robin distribution
- least-connections algorithm
- weighted distribution (health-based)
- ip-hash (session persistence)
- health checks with automatic failover
- configurable retry logic

## quick start

### prerequisites
- nim compiler >= 1.6.0
- windows (currently)

### build
```bash
make build    # build balancer
make tools    # build traffic simulator and benchmark
make test     # run tests
```

### usage
```bash
# copy example config
copy config.example.yaml config.yaml

# edit config.yaml as needed
# start balancer
bin\nymph_balancer.exe
```

## project structure
```
nymph-balancer/
├── src/
│   ├── core/           # balancer, backend_pool, health_checker, algorithms
│   ├── config/         # configuration parsing
│   └── logging/        # logging system
├── tools/              # traffic_simulator, benchmark
├── tests/              # test suite
├── docs/               # documentation
├── bin/                # compiled binaries
└── logs/               # runtime logs
```

## success metrics

| metric | baseline | target |
|--------|----------|--------|
| requests/sec | 500 | 2100 |
| concurrent connections | 100 | 1000+ |
| latency | <50ms | <8ms |

## development phases

- **phase-a**: tcp proxy (1 backend)
- **phase-b**: round-robin (3+ backends)
- **phase-c**: health checks and retry logic
- **phase-d**: advanced algorithms (least-conn, weighted, ip-hash)

## documentation

- [experiment-concept.txt](experiment-concept.txt) - complete experiment design
- [docs/](docs/) - implementation documentation (coming soon)

## coding style

- verb:description naming convention
- lowercase everywhere
- ascii only, no emojis
- no single character variables
- small modules over monoliths

## license

personal experimental project.

---

**experiment goal**: understand load balancing algorithms and tcp connection distribution from first principles.
