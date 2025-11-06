@echo off
REM start_backends.bat: start multiple backend servers for testing

echo starting 3 backend servers...
echo.

start "Backend 9000" cmd /k "bin\simple_backend.exe"
timeout /t 1 /nobreak >nul

start "Backend 9001" cmd /k "bin\simple_backend.exe"
timeout /t 1 /nobreak >nul

start "Backend 9002" cmd /k "bin\simple_backend.exe"

echo.
echo all backends started
echo - backend 1: localhost:9000
echo - backend 2: localhost:9001
echo - backend 3: localhost:9002
echo.
echo press any key to continue...
pause >nul
