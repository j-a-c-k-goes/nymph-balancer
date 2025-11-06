@echo off
REM test_phase_a2.bat: test phase-a.2 config file parsing

echo ========================================
echo nymph-balancer phase-a.2 test
echo ========================================
echo.
echo testing config file parsing:
echo.
echo 1. verify config.yaml exists
if not exist config.yaml (
    echo ERROR: config.yaml not found
    echo copying from config.example.yaml...
    copy config.example.yaml config.yaml
)
echo.
echo 2. start backend server:
echo    bin\simple_backend.exe
echo.
echo 3. start balancer (should load config):
echo    bin\nymph_balancer.exe
echo.
echo 4. verify output shows:
echo    [config] loading from: config.yaml
echo    [config] listen: 0.0.0.0:8080
echo    [config] backend: 127.0.0.1:9000
echo.
echo 5. test with telnet:
echo    telnet localhost 8080
echo.
echo 6. modify config.yaml (change ports)
echo    restart balancer and verify new ports
echo.
echo ========================================
pause
