@echo off
chcp 65001 >nul
echo 正在清除 DeVPN 数据以重置 7 天试用...
G:\WSABuilds\tools\platform-tools\adb.exe connect 127.0.0.1:58526 >nul 2>&1
G:\WSABuilds\tools\platform-tools\adb.exe shell pm clear com.desafa.devpn
echo.
echo 完成！重新打开 DeVPN 即可开始新 7 天试用
pause