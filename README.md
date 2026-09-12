# devpn-link

![GitHub stars](https://img.shields.io/github/stars/X1F2Y3/devpn-link?style=flat-square) ![GitHub](https://img.shields.io/github/license/X1F2Y3/devpn-link?style=flat-square) ![platform](https://img.shields.io/badge/platform-Windows%2011%20%2B%20WSA-blue?style=flat-square)

> **Windows 上让"手机 VPN"接管整台电脑的桥接方案** —— 把 DeVPN 在 Android 里的流量隧道通过 WSA + Termux 代理桥接到 Windows 系统代理，浏览器、命令行、桌面应用全部走隧道。纯脚本、免 Root、无付费代理依赖。

**关键词**：DeVPN Windows / WSA VPN 分享 / Windows 访问 Gemini / 手机 VPN 给电脑用 / Termux 代理桥接 / 破墙 / GitHub 直连 / 系统代理设置

---

## 适用场景（这个仓库帮你解决什么）

- ❌ **谷歌系服务打不开**：`gemini.google.com`、`www.google.com` 一直 `ERR_CONNECTION_TIMED_OUT`？
- ❌ **手机上的 DeVPN 好用，电脑却没有客户端**：DeVPN（`com.desafa.devpn`）只有 Android 版？
- ❌ **WSA 里 VPN 只对虚拟机内生效**，Windows 本体还是被墙？
- ❌ 想给**整台 Windows**（浏览器 + 命令行 + 桌面应用）统一走隧道，而不想再买/再装一套桌面 VPN？

如果击中任意一条，这个仓库就是给你准备的。

## 特性

- 一键恢复整条链路（开机自启、WSA 未启动自动拉起）
- 同时提供 **HTTP 代理**（系统代理全局生效）与 **SOCKS5 代理**（备用）
- 命令行工具同样覆盖（自动写入 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`）
- `devpn_browser` 强制代理浏览器，绕开日常浏览器的代理设置/插件劫持
- 动态定位连接按钮，WSA 重启布局变化也不受影响

## 原理

```
Windows 应用
   │  系统代理 127.0.0.1:18081 (WinINET / 用户环境变量)
   ▼
adb forward (18081/11080 端口映射)
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

所有脚本在仓库根目录即开即用（作者本机路径默认 `G:\DeVPN\`，可自行修改）。

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

## FAQ（常见问题速查）

**Q：DeVPN 有 Windows 电脑版吗？**
没有。DeVPN 只有 Android（Google Play）客户端，这就是本仓库存在的意义。

**Q：手机 VPN 怎么分享/桥接到电脑？**
不需要物理手机。把 DeVPN 装进 WSA 再挂代理桥接到 Windows 系统代理，效果等同"整机 VPN"。Android 手机同理可用本仓库思路（热点 + 代理）。

**Q：WSA 里 VPN 为什么对 Windows 本体不生效？**
因为 DeVPN 的 `tun0` 只存在于 WSA 虚拟机网络栈内，宿主机流量不会经过它。要在 WSA 内起 HTTP/SOCKS 代理（本仓库用 Termux），再用 `adb forward` + Windows 系统代理把流量引进去。

**Q：gemini.google.com / google.com 一直响应超时（ERR_CONNECTION_TIMED_OUT）怎么解决？**
通过本仓库链路：`adb forward` → WSA 内 tinyproxy → DeVPN 隧道即可正常访问。参见"使用"一节，跑一次 `devpn_link.bat`。

**Q：Windows 系统代理怎么设置成走 Android 的 VPN？**
本仓库脚本自动写入 WinINET 注册表（`HKCU\...\Internet Settings`）并广播刷新，同时写入用户级 `HTTP_PROXY`/`HTTPS_PROXY`/`ALL_PROXY`。手动设置亦可：系统代理填 `127.0.0.1:18081`（HTTP）或 `127.0.0.1:11080`（SOCKS5，账号 `u`/密码 `p`）。

**Q：git 推 GitHub 被墙？**
给 git 配置 → `git config --global http.proxy http://127.0.0.1:18081`，即可经隧道正常 push/fetch（配合 GCM + Personal Access Token）。

## 注意事项

- **系统代理覆盖面**：凡读取 WinINET 系统代理 / `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 环境变量的程序都会走隧道；硬编码直连的程序不覆盖。
- **隧道依赖**：DeVPN 一旦 Disconnect、WSA 被关闭或电脑重启，所有走代理的应用会断网，需重跑 `devpn_link.bat`。
- 代理全部绑定 `127.0.0.1`，不对外暴露（SOCKS5 备用口演示账号 `u` / `p`，使用时请自行更换）。
- 脚本中 WSA 启动目标、adb 端口为作者本机值，换机器请按注释调整。

## 支持

如果你觉得有用，**点个 ⭐ Star** 就是对我最大的支持，也方便更多受同问题困扰的人通过搜索找到这个仓库。有改进想法欢迎开 Issue / PR。

## 免责声明

本仓库仅用于个人学习与网络调试。请遵守当地法律法规与所使用服务的条款。