@echo off
REM test_phase_b.bat: test phase-b round-robin load balancing

echo ========================================
echo nymph-balancer phase-b test
echo ========================================
echo.
echo testing round-robin across 3 backends:
echo.
echo 1. start 3 backend servers:
echo    bin\simple_backend.exe 9000
echo    bin\simple_backend.exe 9001
echo    bin\simple_backend.exe 9002
echo.
echo 2. verify config.yaml has 3 backends configured
echo.
echo 3. start balancer:
echo    bin\nymph_balancer.exe
echo.
echo 4. verify balancer shows:
echo    [config] backends: 3 configured
echo    [balancer] backend pool: 3 servers
echo.
echo 5. connect multiple times with telnet:
echo    telnet localhost 8080
echo    send: test1
echo    expect: backend_9000: test1
echo.
echo    telnet localhost 8080
echo    send: test2
echo    expect: backend_9001: test2
echo.
echo    telnet localhost 8080
echo    send: test3
echo    expect: backend_9002: test3
echo.
echo    telnet localhost 8080
echo    send: test4
echo    expect: backend_9000: test4 (cycles back)
echo.
echo 6. verify round-robin distribution in logs
echo.
echo ========================================
pause
