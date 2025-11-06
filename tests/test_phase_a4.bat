@echo off
REM test_phase_a4.bat: test phase-a.4 error handling

echo ========================================
echo nymph-balancer phase-a.4 test
echo ========================================
echo.
echo testing connection error handling:
echo.
echo test 1: backend unreachable
echo   1. do NOT start backend server
echo   2. start balancer: bin\nymph_balancer.exe
echo   3. connect with telnet: telnet localhost 8080
echo   4. verify log shows: backend unreachable
echo.
echo test 2: backend timeout
echo   1. modify config.yaml: connect_timeout: 1000
echo   2. start slow/unresponsive backend
echo   3. connect with telnet
echo   4. verify log shows: backend connection timeout
echo.
echo test 3: backend disconnect during transfer
echo   1. start backend: bin\simple_backend.exe
echo   2. start balancer: bin\nymph_balancer.exe
echo   3. connect with telnet
echo   4. kill backend during transfer
echo   5. verify log shows: backend disconnected during response
echo.
echo test 4: graceful recovery
echo   1. restart backend after failure
echo   2. new connections should work
echo   3. verify balancer continues accepting connections
echo.
echo ========================================
pause
