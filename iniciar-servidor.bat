@echo off

start "Munchify - Servidor" cmd /k "cd /d "%~dp0backend" && npm start"
timeout /t 4 /nobreak >nul
start "Munchify - Tunel" cmd /k ""%LOCALAPPDATA%\Microsoft\WinGet\Links\ngrok.exe" http --url=elenora-unwoeful-lyndsey.ngrok-free.dev 3000"
