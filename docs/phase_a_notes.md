# phase-a: tcp proxy

## overview

phase-a implements a basic tcp proxy that forwards connections from clients to a single backend server.

## milestones

- [x] **a.0**: project setup, structure
  - created directory structure
  - makefile for build automation
  - readme with project overview
  - gitignore for nim projects

- [x] **a.1**: accept single connection, forward to 1 backend
  - basic tcp socket handling
  - bidirectional data forwarding
  - blocking implementation (simple)
  - builds successfully
  - tested with telnet - works correctly
  - client -> balancer:8080 -> backend:9000 -> response flow verified

- [x] **a.2**: add config file parsing (backend address)
  - simple yaml parser implemented
  - configurable backend host/port
  - configurable listen host/port
  - defaults if config file missing
  - builds successfully

- [x] **a.3**: add basic logging
  - connection events logged
  - error logging implemented
  - log to file (logs/balancer.log)
  - log levels: INFO, WARN, ERROR, DEBUG
  - timestamps on all entries
  - component-based logging
  - builds successfully

- [ ] **a.4**: handle connection errors gracefully
  - backend unreachable
  - client disconnect
  - timeout handling

## current implementation

### balancer.nim
- listens on port 8080
- forwards to backend at 127.0.0.1:9000
- blocking, single-threaded
- handles one connection at a time

### simple_backend.nim
- test backend server
- listens on port 9000
- echoes received data with prefix

## testing phase-a.1

```bash
# terminal 1: start backend
nim c -r tools\simple_backend.nim

# terminal 2: start balancer
make build
bin\nymph_balancer.exe

# terminal 3: test with telnet
telnet localhost 8080
```

## known limitations

- blocking implementation (one connection at a time)
- hardcoded backend address
- no logging to file
- no error recovery
- no configuration file

these will be addressed in subsequent milestones.

## next steps

- test a.3 implementation (logging)
- move to a.4 (handle connection errors gracefully)
