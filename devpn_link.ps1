param([switch]$Off)
$ErrorActionPreference = "Stop"
$adb = "G:\WSABuilds\tools\platform-tools\adb.exe"
$ip = "127.0.0.1:58526"

function Set-WinProxy([string]$srv) {
  $k = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
  if ($srv) { Set-ItemProperty -Path $k -Name ProxyEnable -Value 1; Set-ItemProperty -Path $k -Name ProxyServer -Value $srv; Set-ItemProperty -Path $k -Name ProxyOverride -Value "<local>" }
  else { Set-ItemProperty -Path $k -Name ProxyEnable -Value 0 }
  Add-Type @"
using System;using System.Runtime.InteropServices;
public class W { [DllImport("wininet.dll",SetLastError=true)] public static extern bool InternetSetOption(IntPtr h,int opt,IntPtr buf,int len); }
"@
  [void][W]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0)
  [void][W]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)
}

if ($Off) {
  Set-WinProxy $null
  [Environment]::SetEnvironmentVariable("HTTP_PROXY",$null,"User")
  [Environment]::SetEnvironmentVariable("HTTPS_PROXY",$null,"User")
  [Environment]::SetEnvironmentVariable("ALL_PROXY",$null,"User")
  "system proxy: OFF"
  exit 0
}

"== 1. adb connect (auto-start WSA if needed) =="
function Start-WSA {
  $pkg = "MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe!App"
  Start-Process "shell:AppsFolder\$pkg" | Out-Null
}
& $adb connect $ip 2>&1 | Out-Null
$dev = (& $adb devices) -match "device$"
if (-not $dev) {
  "WSA not up - starting it..."
  Start-WSA
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 3
    & $adb connect $ip 2>&1 | Out-Null
    $dev = (& $adb devices) -match "device$"
    if ($dev) { break }
  }
}
if (-not $dev) { "adb device still not ready after 120s"; exit 1 }
"ok"

"== 2. ensure DeVPN tunnel (tun0) =="
$tun = (& $adb shell /system/bin/ip addr show) -match "tun0"
if (-not $tun) {
  & $adb shell am start -n com.desafa.devpn/.MainActivity | Out-Null
  Start-Sleep -Seconds 3
  & $adb shell input tap 1095 1064 | Out-Null
  for ($i=0; $i -lt 10; $i++) {
    Start-Sleep -Seconds 3
    $tun = (& $adb shell /system/bin/ip addr show) -match "tun0"
    if ($tun) { break }
  }
}
if (-not $tun) { "tun0 not up - DeVPN connect failed? run reset or connect manually"; exit 1 }
"tun0 up"

"== 3. ensure termux proxies =="
$script = @'
B=/data/data/com.termux/files
export HOME=$B/home PREFIX=$B/usr TMPDIR=$B/usr/tmp LD_LIBRARY_PATH=$B/usr/lib PATH=$B/usr/bin:$B/usr/bin/applets
C=$B/usr/etc/tinyproxy/tinyproxy.conf
[ -f $C ] && sed -i 's/^Port .*/Port 8118/' $C
grep -q '^Listen ' $C || echo 'Listen 127.0.0.1' >> $C
grep -q '^Allow 127' $C || echo 'Allow 127.0.0.1' >> $C
pkill -f tinyproxy 2>/dev/null; pkill -f microsocks 2>/dev/null; sleep 1
nohup $B/usr/bin/tinyproxy -c $C -d >/dev/null 2>&1 &
nohup $B/usr/bin/microsocks -i 127.0.0.1 -p 1080 -u u -P p >/dev/null 2>&1 &
sleep 2
ps -A 2>/dev/null | grep -qE 'tinyproxy' && echo PROXY_OK || echo PROXY_FAIL
'@
$res = ($script | & $adb shell "run-as com.termux env HOME=/data/data/com.termux/files/home PREFIX=/data/data/com.termux/files/usr TMPDIR=/data/data/com.termux/files/usr/tmp LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets /data/data/com.termux/files/usr/bin/bash -s") 2>&1
$res | Select-Object -Last 1

"== 4. adb forward =="
& $adb forward --remove-all 2>&1 | Out-Null
& $adb forward tcp:18081 tcp:8118 2>&1 | Out-Null
& $adb forward tcp:11080 tcp:1080 2>&1 | Out-Null
& $adb forward --list

"== 5. Windows system proxy =="
Set-WinProxy "127.0.0.1:18081"
[Environment]::SetEnvironmentVariable("HTTP_PROXY","http://127.0.0.1:18081","User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY","http://127.0.0.1:18081","User")
[Environment]::SetEnvironmentVariable("ALL_PROXY","socks5://127.0.0.1:11080","User")
"127.0.0.1:18081 (WinINET + user env vars for CLI)"

"== 6. verify (exit IP via tunnel) =="
$ip = curl.exe -s -x http://127.0.0.1:18081 -m 25 https://api.ipify.org 2>$null
if ($ip) { "OK exit IP = $ip" } else { "verify via curl failed - try browser gemini directly" }

"== done. Browser (Edge/Chrome) now routes through DeVPN. =="