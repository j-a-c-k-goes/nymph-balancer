# config: configuration file parsing

import std/[parseutils, strutils, os]

type
  BalancerConfig* = object
    listen_port*: int
    listen_host*: string
    backend_host*: string
    backend_port*: int

proc parse_yaml_simple(filepath: string): BalancerConfig =
  ## parse simple yaml config file
  result.listen_port = 8080
  result.listen_host = "0.0.0.0"
  result.backend_host = "127.0.0.1"
  result.backend_port = 9000
  
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
    
    elif "host:" in trimmed and "backend" notin trimmed:
      let parts = trimmed.split(":", 1)
      if parts.len >= 2:
        result.backend_host = parts[1].strip().strip(chars = {'"', '\''})
    
    elif "port:" in trimmed and "listen" notin trimmed:
      let parts = trimmed.split(":")
      if parts.len >= 2:
        discard parseInt(parts[1].strip(), result.backend_port)

proc load_config*(filepath: string = "config.yaml"): BalancerConfig =
  ## load configuration from yaml file
  echo "[config] loading from: ", filepath
  result = parse_yaml_simple(filepath)
  echo "[config] listen: ", result.listen_host, ":", result.listen_port
  echo "[config] backend: ", result.backend_host, ":", result.backend_port
