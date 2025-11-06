# logger: logging system for balancer

import std/[times, os]

type
  LogLevel* = enum
    INFO, WARN, ERROR, DEBUG

var
  log_file: File          # log file handle
  log_enabled = false     # whether logging to file is active

proc init_logger*(filepath: string = "logs/balancer.log") =
  ## initialize logger and open log file
  try:
    createDir(parentDir(filepath))
    log_file = open(filepath, fmAppend)
    log_enabled = true
    echo "[logger] initialized: ", filepath
  except:
    echo "[logger] failed to open log file: ", getCurrentExceptionMsg()
    log_enabled = false

proc close_logger*() =
  ## close log file
  if log_enabled:
    log_file.close()
    log_enabled = false

proc write_log*(level: LogLevel, component: string, message: string) =
  ## write log entry to file and stdout
  let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
  let level_str = $level
  let log_line = timestamp & " [" & level_str & "] [" & component & "] " & message
  
  # write to stdout
  echo log_line
  
  # write to file
  if log_enabled:
    try:
      log_file.writeLine(log_line)
      log_file.flushFile()
    except:
      discard

proc log_info*(component: string, message: string) =
  ## log info level message
  write_log(INFO, component, message)

proc log_warn*(component: string, message: string) =
  ## log warning level message
  write_log(WARN, component, message)

proc log_error*(component: string, message: string) =
  ## log error level message
  write_log(ERROR, component, message)

proc log_debug*(component: string, message: string) =
  ## log debug level message
  write_log(DEBUG, component, message)
