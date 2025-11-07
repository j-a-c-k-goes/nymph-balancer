import core/[balancer_worker_pool, backend_pool]
import config/config as cfg
import logging/logger

when isMainModule:
  init_logger()
  let balancer_config = cfg.load_config("config.yaml")
  var pool            = init_backend_pool()
  for backend_config in balancer_config.backends:
    pool.add_backend(backend_config.host, backend_config.port)
  log_info("main", "nymph-balancer starting")
  log_info("main", "backends: " & $pool.backend_count())  
  start_balancer(balancer_config.listen_port, pool)
