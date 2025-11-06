@echo off
REM test_phase_a1.bat: test phase-a.1 tcp proxy functionality

echo ========================================
echo nymph-balancer phase-a.1 test
echo ========================================
echo.
echo this test requires manual verification:
echo.
echo 1. start backend server:
echo    bin\simple_backend.exe
echo.
echo 2. start balancer (in another terminal):
echo    bin\nymph_balancer.exe
echo.
echo 3. test with telnet (in another terminal):
echo    telnet localhost 8080
echo    type some text and press enter
echo.
echo 4. verify:
echo    - backend receives the data
echo    - backend echoes back with prefix
echo    - client receives the response
echo.
echo ========================================
pause
