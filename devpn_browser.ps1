# ASCII only. Opens Edge/Chrome forced through the DeVPN tunnel.
param([string]$BK = "edge")
Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","G:\DeVPN\devpn_link.ps1")
$url = "https://gemini.google.com"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$exe = $null
if ($BK -eq "chrome") {
  if (Test-Path $chrome) { $exe = $chrome; $prof = "G:\DeVPN\chrome-vpn-profile" }
  elseif (Test-Path $edge) { $exe = $edge; $prof = "G:\DeVPN\edge-vpn-profile" }
} else {
  if (Test-Path $edge) { $exe = $edge; $prof = "G:\DeVPN\edge-vpn-profile" }
  elseif (Test-Path $chrome) { $exe = $chrome; $prof = "G:\DeVPN\chrome-vpn-profile" }
}
if (-not $exe) { Write-Host "no browser found"; exit 1 }
$args = @("--no-first-run","--proxy-server=http://127.0.0.1:18081","--proxy-bypass-list=<local>","--user-data-dir=$prof",$url)
Start-Process -FilePath $exe -ArgumentList $args
Write-Host "opened: $exe with forced proxy -> $url"