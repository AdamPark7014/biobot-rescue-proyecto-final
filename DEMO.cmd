@echo off
cd /d "%~dp0"
start "BioBot-Rescue - monitor en vivo" cmd /c MONITOR.cmd
timeout /t 3 /nobreak > nul
start "BioBot-Rescue - ordenes" cmd /c TERMINAL.cmd
