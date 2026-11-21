@echo off
rem Carga la red en las tres DE10-Lite y verifica los enlaces. Usar cada vez que se enciendan las tarjetas.
rem Siempre vuelve a cargar las tres, para que ninguna se quede con una version anterior.
title BioBot-Rescue - cargar la red
cd /d "%~dp0"
pwsh -NoProfile -File cargar_red.ps1 -Todo
pause
