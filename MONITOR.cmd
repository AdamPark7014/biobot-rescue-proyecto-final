@echo off
title BioBot-Rescue - monitor en vivo
cd /d "%~dp0"
C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_stp.exe -t pc/terminal.tcl vivo
pause
