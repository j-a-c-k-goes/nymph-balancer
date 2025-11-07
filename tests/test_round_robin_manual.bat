@echo off
REM test_round_robin_manual.bat: manual round-robin verification

echo ========================================
echo round-robin manual test
echo ========================================
echo.
echo IMPORTANT: balancer is blocking (phase-a limitation)
echo you must CLOSE each connection to see round-robin
echo.
echo 1. start 3 backends in separate terminals:
echo    bin\simple_backend.exe 9000
echo    bin\simple_backend.exe 9001
echo    bin\simple_backend.exe 9002
echo.
echo 2. start balancer:
echo    bin\nymph_balancer.exe
echo.
echo 3. test connection 1:
echo    telnet localhost 8080
echo    type: test1
echo    observe response: backend_9000: test1
echo    CLOSE CONNECTION: Ctrl+] then type "quit"
echo.
echo 4. test connection 2:
echo    telnet localhost 8080
echo    type: test2
echo    observe response: backend_9001: test2
echo    CLOSE CONNECTION: Ctrl+] then type "quit"
echo.
echo 5. test connection 3:
echo    telnet localhost 8080
echo    type: test3
echo    observe response: backend_9002: test3
echo    CLOSE CONNECTION: Ctrl+] then type "quit"
echo.
echo 6. test connection 4 (cycles back):
echo    telnet localhost 8080
echo    type: test4
echo    observe response: backend_9000: test4
echo.
echo OR use benchmark tool for automatic testing:
echo    bin\benchmark.exe 10
echo    check logs to see round-robin distribution
echo.
echo ========================================
pause
