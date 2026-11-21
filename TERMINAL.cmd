@echo off
rem Ordenes para la red de tres FPGA. Lo que se escribe aqui lo ejecuta el monitor en vivo
rem (MONITOR.cmd), que debe estar abierto: ahi se ve el resultado al instante.
title BioBot-Rescue - ordenes
cd /d "%~dp0"
echo.
echo  Ordenes para las cucarachas (el resultado se ve en la ventana del MONITOR):
echo.
echo    pos A 31 0      pone la mochila A en x = 31 m, y = 0 m  (el receptor esta en 0, 0)
echo    pos A 32 0      a 32 m o mas ya no se oye
echo    pos B 4.5 3     pone la mochila B cerca de la entrada
echo    pos A sw        la posicion vuelve a los interruptores SW9-SW6
echo    temp A 36       el sensor termico de A lee 36 grados (detecta de 35 a 38)
echo    temp A sw       la temperatura vuelve a los interruptores SW5-SW0
echo    boton B         aprieta el boton de ayuda de B
echo    vista 1         displays del receptor: 0 r Pd, 1 persona X/Y, 2 distancia A-B, 3 rumbos
echo    vista sw        la vista del receptor vuelve a sus interruptores SW1-SW0
echo    reset           reinicia las tres tarjetas
echo    suelta          todo vuelve a los interruptores
echo    salir
echo.
:otra
set "orden="
set /p "orden=biobot> "
if /i "%orden%"=="salir" exit /b
if not "%orden%"=="" >> pc\ordenes.txt echo %orden%
goto otra
