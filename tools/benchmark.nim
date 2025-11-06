# benchmark: performance measurement tool

import std/[net, times, os, strutils]

type
  BenchmarkResult = object
    total_requests: int       # total requests sent
    successful: int           # successful responses
    failed: int               # failed requests
    duration_ms: float        # total duration (milliseconds)
    requests_per_sec: float   # throughput

proc send_request(host: string, port: int, data: string): bool =
  ## send single request and receive response
  var client = newSocket()
  try:
    client.connect(host, Port(port), timeout = 5000)
    discard client.send(data.cstring, data.len)
    
    var buffer: array[4096, char]
    let bytes_read = client.recv(addr buffer[0], 4096)
    
    client.close()
    return bytes_read > 0
  except:
    try:
      client.close()
    except:
      discard
    return false

proc run_benchmark(host: string, port: int, num_requests: int): BenchmarkResult =
  ## run benchmark with specified number of requests
  result.total_requests = num_requests
  result.successful = 0
  result.failed = 0
  
  echo "starting benchmark..."
  echo "target: ", host, ":", port
  echo "requests: ", num_requests
  echo ""
  
  let start_time = epochTime()
  
  for index in 1..num_requests:
    let success = send_request(host, port, "benchmark_test_" & $index & "\n")
    
    if success:
      result.successful += 1
    else:
      result.failed += 1
    
    # progress indicator every 100 requests
    if index mod 100 == 0:
      echo "progress: ", index, "/", num_requests
  
  let end_time = epochTime()
  result.duration_ms = (end_time - start_time) * 1000.0
  result.requests_per_sec = float(result.successful) / (result.duration_ms / 1000.0)

proc display_results(result: BenchmarkResult) =
  ## display benchmark results
  echo ""
  echo "=========================================="
  echo "benchmark results"
  echo "=========================================="
  echo "total requests:    ", result.total_requests
  echo "successful:        ", result.successful
  echo "failed:            ", result.failed
  echo "duration:          ", result.duration_ms.formatFloat(ffDecimal, 2), " ms"
  echo "requests/sec:      ", result.requests_per_sec.formatFloat(ffDecimal, 2)
  echo "=========================================="

proc main() =
  ## main benchmark entry point
  var host = "127.0.0.1"
  var port = 8080
  var num_requests = 500
  
  # parse command line arguments
  if paramCount() >= 1:
    try:
      num_requests = parseInt(paramStr(1))
    except:
      echo "invalid request count, using default: ", num_requests
  
  if paramCount() >= 2:
    try:
      port = parseInt(paramStr(2))
    except:
      echo "invalid port, using default: ", port
  
  # run benchmark
  let result = run_benchmark(host, port, num_requests)
  display_results(result)

when isMainModule:
  main()
