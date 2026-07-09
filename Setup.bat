@echo off
title SmartPolisher Installer
cd /d "%~dp0"
echo Running SmartPolisher Setup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Install-SmartPolisher.ps1"
pause
