@echo off
title SmartPolisher Killer
cd /d "%~dp0"

set "PID_FILE=%~dp0smartpolisher.pid"

if exist "%PID_FILE%" (
    set /p PID=<"%PID_FILE%"
    echo Stopping SmartPolisher (PID: %PID%)...
    taskkill /f /pid %PID% > nul 2>&1
    del "%PID_FILE%" > nul 2>&1
    echo SmartPolisher stopped successfully.
) else (
    echo SmartPolisher is not running (no PID file found).
)
pause
