@echo off
REM test_phase_a3.bat: test phase-a.3 logging functionality

echo ========================================
echo nymph-balancer phase-a.3 test
echo ========================================
echo.
echo testing logging to file:
echo.
echo 1. start backend server:
echo    bin\simple_backend.exe
echo.
echo 2. start balancer:
echo    bin\nymph_balancer.exe
echo.
echo 3. verify logs directory created
echo    dir logs
echo.
echo 4. test connection with telnet:
echo    telnet localhost 8080
echo    send some data
echo.
echo 5. check log file:
echo    type logs\balancer.log
echo.
echo 6. verify log entries show:
echo    - timestamp
echo    - log level (INFO, WARN, ERROR, DEBUG)
echo    - component name
echo    - message
echo.
echo ========================================
pause
