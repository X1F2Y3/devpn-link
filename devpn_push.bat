@echo off
setlocal
set MSG=%*
if "%MSG%"=="" set "MSG=update"
cd /d G:\DeVPN
git add -A
git commit -m "%MSG%"
git push
endlocal