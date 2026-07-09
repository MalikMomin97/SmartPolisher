@echo off
title SmartPolisher Launcher
cd /d "%~dp0"

REM Stop any already running instance
call Stop-SmartPolisher.bat > nul 2>&1

echo Starting SmartPolisher in the background...
start "" powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0SmartPolisher.ps1"
exit
