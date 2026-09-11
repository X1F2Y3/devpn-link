@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "G:\DeVPN\devpn_browser.ps1" %*
endlocal