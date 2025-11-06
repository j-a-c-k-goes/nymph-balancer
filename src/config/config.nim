# config: configuration file parsing

import std/[parseutils, strutils, os]

type
  BackendConfig* = object
    host*: string           # backend server address
    port*: int              # backend server port
  
  BalancerConfig* = object
    listen_port*: int       # port to listen on
    listen_host*: string    # host address to bind
    backends*: seq[BackendConfig]  # list of backend servers
    connect_timeout*: int   # connection timeout (milliseconds)
    recv_timeout*: int      # receive timeout (milliseconds)

proc parse_yaml_simple(filepath: string): BalancerConfig =
  ## parse simple yaml config file
  result.listen_port = 8080 
  result.listen_host = "0.0.0.0"
  result.backends = @[]
  result.connect_timeout = 5000
  result.recv_timeout = 10000
  
  if not fileExists(filepath):
    echo "[config] file not found: ", filepath, ", using defaults"
    return
  
  let content = readFile(filepath)
  for line in content.splitLines():
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    
    if "listen_port:" in trimmed:
      let parts = trimmed.split(":")
      if parts.len >= 2:
        discard parseInt(parts[1].strip(), result.listen_port)
    
    elif "listen_host:" in trimmed:
      let parts = trimmed.split(":", 1)
      if parts.len >= 2:
        result.listen_host = parts[1].strip().strip(chars = {'"', '\''})
    
    elif trimmed.startsWith("- host:"):
      let parts = trimmed.split(":", 1)
      if parts.len >= 2:
        let host = parts[1].strip().strip(chars = {'"', '\''})
        result.backends.add(BackendConfig(host: host, port: 9000))
    
    elif trimmed.startsWith("port:") and result.backends.len > 0:
      let parts = trimmed.split(":")
      if parts.len >= 2:
        var port: int
        if parseInt(parts[1].strip(), port) > 0:
          result.backends[^1].port = port
    
    elif "connect_timeout:" in trimmed:
      let parts = trimmed.split(":")
      if parts.len >= 2:
        discard parseInt(parts[1].strip(), result.connect_timeout)
    
    elif "recv_timeout:" in trimmed:
      let parts = trimmed.split(":")
      if parts.len >= 2:
        discard parseInt(parts[1].strip(), result.recv_timeout)

proc load_config*(filepath: string = "config.yaml"): BalancerConfig =
  ## load configuration from yaml file
  echo "[config] loading from: ", filepath
  result = parse_yaml_simple(filepath)
  echo "[config] listen: ", result.listen_host, ":", result.listen_port
  echo "[config] backends: ", result.backends.len, " configured"
  for backend in result.backends:
    echo "[config]   - ", backend.host, ":", backend.port
