@echo off
rem Abre el servidor de Munchify y el tunel de ngrok (direccion fija) en dos ventanas.
rem Antes de ejecutarlo: enciende MySQL en XAMPP.

start "Munchify - Servidor" cmd /k "cd /d "%~dp0backend" && npm start"
timeout /t 4 /nobreak >nul
start "Munchify - Tunel" cmd /k ""%LOCALAPPDATA%\Microsoft\WinGet\Links\ngrok.exe" http --url=elenora-unwoeful-lyndsey.ngrok-free.dev 3000"
