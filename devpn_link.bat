@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "G:\DeVPN\devpn_link.ps1"
if errorlevel 1 pause