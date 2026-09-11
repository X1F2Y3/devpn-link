# devpn-link

把 Android 端 DeVPN（`com.desafa.devpn`）的流量隧道接到 Windows，实现"整个电脑的流量走手机 VPN"。纯脚本驱动，不依赖任何付费代理工具。

## 原理

```
Windows 应用
   │  系统代理 127.0.0.1:18081 (WinINET / 用户环境变量)
   ▼
adb forward (13081/11080 端口映射)
   ▼
WSA 内 Termux —— tinyproxy(HTTP) / microsocks(SOCKS5)
   ▼
Android 系统路由 → DeVPN 隧道（tun0）
   ▼
互联网（VPN 出口）
```

关键点：
- DeVPN 只跑在 WSA（Windows Subsystem for Android）里，隧道只覆盖 WSA 虚拟机内部。
- 在 WSA 内跑 Tinyproxy / Microsocks 代理，把"隧道里的流量"变成本地代理。
- 用 `adb forward` 把 WSA 内代理端口映射到宿主机，再设置 Windows 系统代理，整机流量即走隧道。

## 使用

所有脚本在仓库根目录即开即用（路径默认 `G:\DeVPN\`，可自行修改脚本内路径）。

| 脚本 | 作用 |
| --- | --- |
| `devpn_link.ps1` / `.bat` | 一键恢复全链路：拉起 WSA(若未开) → 连 DeVPN → 起代理 → 端口映射 → 设系统代理 → 验证出口 IP |
| `devpn_browser.ps1` / `.bat` | 用"强制走隧道"的独立 Edge 打开 gemini.google.com（`chrome` 参数可换 Chrome） |
| `devpn_reset.bat` | 清理 DeVPN 应用数据，重置 7 天试用期 |
| `devpn_autostart.bat` | 开机自启入口（放入 `shell:startup` 目录） |

- `devpn_link.ps1 -Off`：关闭系统代理并清掉环境变量。
- 状态控制：开始菜单里打开 DeVPN / Termux 窗口即可查看与管理（关窗口不断隧道）。

## 环境要求（Windows）

- Windows 11（启用虚拟化） + **WSA**（推荐 WSABuilds NoGApps 版，见 https://github.com/MustardChef/WSABuilds）
- Android 平台工具 **adb**（本仓库脚本默认 `<WSABuilds>\tools\platform-tools\adb.exe`）
- WSA 内安装：
  - DeVPN APK（`com.desafa.devpn`）
  - Termux（GitHub Release 的 `x86_64` 包，适配 WSA）
  - Termux 内：`pkg install tinyproxy microsocks`
- WSA 开发人员模式已开启（`adb connect 127.0.0.1:<端口>`，脚本默认 `58526`）

> 首次连接 DeVPN 若卡在授权，运行：
> `adb shell cmd appops set com.desafa.devpn ACTIVATE_VPN allow` 后重连。

## 注意事项

- **系统代理覆盖面**：凡读取 WinINET 系统代理 / `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 环境变量的程序都会走隧道；硬编码直连的程序不覆盖。
- **隧道依赖**：DeVPN 一旦 Disconnect、WSA 被关闭或电脑重启，所有走代理的应用会断网，需重跑 `devpn_link.bat`。
- 代理全部绑定 `127.0.0.1`，不对外暴露（SOCKS5 备用口 `127.0.0.1:11080`，演示账号 `u` / `p`，使用时请自行更换）。
- 脚本中 WSA 启动目标、adb 端口为作者本机值，换机器请按注释调整。

## 免责声明

本仓库仅用于个人学习与网络调试。请遵守当地法律法规与所使用服务的条款。