@echo off
title BioBot-Rescue - cargar la red
cd /d "%~dp0"
pwsh -NoProfile -File cargar_red.ps1 -Todo
pause
