@echo off
REM test_phase_b4.bat: benchmark phase-b performance

echo ========================================
echo nymph-balancer phase-b.4 benchmark
echo ========================================
echo.
echo benchmark 1: single backend baseline
echo.
echo 1. edit config.yaml - use only 1 backend:
echo    backends:
echo      - host: "127.0.0.1"
echo        port: 9000
echo.
echo 2. start backend:
echo    bin\simple_backend.exe 9000
echo.
echo 3. start balancer:
echo    bin\nymph_balancer.exe
echo.
echo 4. run benchmark (500 requests):
echo    bin\benchmark.exe 500
echo.
echo 5. record results (requests/sec)
echo.
echo ========================================
echo.
echo benchmark 2: three backends (round-robin)
echo.
echo 1. edit config.yaml - use 3 backends:
echo    backends:
echo      - host: "127.0.0.1"
echo        port: 9000
echo      - host: "127.0.0.1"
echo        port: 9001
echo      - host: "127.0.0.1"
echo        port: 9002
echo.
echo 2. start 3 backends:
echo    bin\simple_backend.exe 9000
echo    bin\simple_backend.exe 9001
echo    bin\simple_backend.exe 9002
echo.
echo 3. restart balancer:
echo    bin\nymph_balancer.exe
echo.
echo 4. run benchmark (500 requests):
echo    bin\benchmark.exe 500
echo.
echo 5. record results (requests/sec)
echo.
echo 6. compare: 3 backends vs 1 backend
echo.
echo ========================================
pause
