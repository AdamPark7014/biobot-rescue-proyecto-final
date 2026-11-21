@echo off
rem Abre las dos ventanas de la demostracion: el monitor en vivo y la de ordenes.
rem Antes, con las tarjetas recien encendidas, correr CARGAR_RED.cmd.
cd /d "%~dp0"
start "BioBot-Rescue - monitor en vivo" cmd /c MONITOR.cmd
timeout /t 3 /nobreak > nul
start "BioBot-Rescue - ordenes" cmd /c TERMINAL.cmd
