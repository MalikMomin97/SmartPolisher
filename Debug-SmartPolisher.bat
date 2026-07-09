@echo off
title SmartPolisher Debug Console
cd /d "%~dp0"
echo Starting SmartPolisher in Debug Mode (window will stay open)...
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0SmartPolisher.ps1"
pause
