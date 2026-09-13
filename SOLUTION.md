# DeVPN PC 端原生化重构方案与架构设计规范 (RFC)

> **目标**：彻底淘汰 WSA / 安卓虚拟机套娃架构，以 **< 40MB 磁盘、< 40MB 内存、零后台残留、纯原生系统托盘体验** 在 Windows 上稳定运行 DeVPN 代理服务。

---

## 目录
1. [历史方案审计与根因分析（为什么老方案像病毒一样弹窗且崩溃）](#1-历史方案审计与根因分析)
2. [APK 逆向解包与底层技术栈发现](#2-apk-逆向解包与底层技术栈发现)
3. [目标架构设计 (Native Architecture)](#3-目标架构设计-native-architecture)
4. [核心模块技术实现规范（供高阶代码模型实施）](#4-核心模块技术实现规范)
5. [资源开销与指标对比](#5-资源开销与指标对比)
6. [落地执行路线图](#6-落地执行路线图)

---

## 1. 历史方案审计与根因分析

前期方案试图通过 **Windows 宿主机 -> ADB forward -> WSA(安卓虚拟机) -> 代理 APP(apollgo) -> DeVPN APP -> 出口** 的链路运行，导致以下致命问题：

### 1.1 "病毒式弹窗"根因
- `devpn_daemon.ps1`、`DeVPNClient.cs`（内置 `WatchdogLoop`）与 `devpn_link.ps1` 三者独立并发运行。
- 三者均采用无重试上限、无退避策略的 `while ($true)` 循环，每 45 秒探测 ADB 端口 `58526`。
- 一旦 WSA 因空闲休眠（WSA 原生内建机制，约 10 分钟无交互自动挂起），脚本便通过 `Start-Process explorer.exe shell:AppsFolder\...` 重复唤醒 WSA。
- **实测日志**：在 3 小时内连续触发了 60+ 次无意义的拉起与超时，导致 Windows 桌面不断弹出 WSA 设置与应用窗口。

### 1.2 磁盘空间爆炸（占满 C 盘）
- WSA 属于 UWP 容器架构，运行时数据强行写入 `%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\`，无法安全软链接至其他盘符。
- 仅运行时缓存就占用了 **2.37 GB**，加上系统镜像 VHDX（**1.8 GB**）和临时解压文件，整体占用突破 **6.4 GB**，直接违背了用户 `< 1GB` 的活动空间红线。

### 1.3 链路脆弱且逻辑断裂
- **端口冲突**：`devpn_link.ps1` 指向 `18081 / 8118`，`DeVPNClient.cs` 指向 `8080 / 1080`，`proxy_on.ps1` 指向 `8080`，从未统一。
- **包名写错**：代码中写死 `com.sshh12.apollgo`，实际安装包为 `io.sshh.apollgo`，代理应用压根无法自启。
- **坐标硬编码**：`DeVPNClient.cs` 靠 `input tap 1943 1090` 点击“Quick connect”，换任意屏幕分辨率或缩放比例即失效。

---

## 2. APK 逆向解包与底层技术栈发现

对 `devpn.apk` 的资产解构揭示了核心事实：

```text
devpn.apk
├── assets/
│   ├── index.android.bundle             <-- React Native 编译后的前端交互与业务代码
│   └── singbox/
│       ├── AdGuardSDNSFilterSingBox.srs <-- sing-box 编译规则集
│       ├── chrome-doh.json              <-- sing-box DNS 配置
│       ├── geoip-cn.srs                 <-- sing-box GeoIP 规则
│       └── geolocation-cn.srs           <-- sing-box 地理位置规则
└── lib/arm64-v8a/                       <-- 无私有加密驱动，仅集成标准库
```

### 关键结论：
1. **DeVPN 本质上是 sing-box**：它不是私有加密 VPN，而是使用开源通用代理内核 **sing-box**，外层套了 React Native 壳。
2. **底层协议是通用的**：节点协议为标准的 VLESS / Shadowsocks / Hysteria / WireGuard 之一。
3. **试用期重置机制**：移动端“清除全部数据即可重置 7 天免费试用”，说明其认证不依赖手机硬件不可变指纹（IMEI），仅依赖本地存储的随机 `DeviceID / UUID / AndroidID`。每次向后端 API 注册新 ID 即可换取有效节点与订阅凭证。

---

## 3. 目标架构设计 (Native Architecture)

```
+-------------------------------------------------------------------+
|                        Windows 宿主机                             |
|                                                                   |
|   +-----------------------------------------------------------+   |
|   |          DeVPN Native Client (原生轻量托盘程序)           |   |
|   |   - 单实例互斥 (Mutex: Global\DeVPN_Native_Client)        |   |
|   |   - 托盘图标：已连接(绿) / 未连接(灰)                     |   |
|   |   - 设备 ID 自动刷新 / 节点获取器                         |   |
|   |   - Windows 系统代理 (WinINet) / TUN 驱动生命周期管理     |   |
|   +-----------------------------+-----------------------------+   |
|                                 | (Child Process / Job Object)    |
|                                 v                                 |
|   +-----------------------------------------------------------+   |
|   |         sing-box.exe (官方 Windows 原生内核, ~20MB)        |   |
|   |   - 读取生成的 config.json                                 |   |
|   |   - 入站：Mixed (HTTP/SOCKS5 127.0.0.1:20808) 或 TUN 网卡 |   |
|   |   - 出站：DeVPN 代理节点                                  |   |
|   +-----------------------------+-----------------------------+   |
+---------------------------------|---------------------------------+
                                  | (加密流量)
                                  v
                            Internet 出口
```

---

## 4. 核心模块技术实现规范

高阶编码模型在实施时，需按照以下模块逐步交付：

### 模块 1：逆向提取 API 接口与节点生成 (`node_fetcher`)
- **分析文件**：`devpn.apk` 内提取的 `assets/index.android.bundle`。
- **任务**：
  1. 搜索关键字符串：`register`、`trial`、`device_id`、`token`、`servers`、`node`、`sing-box`、`https://`。
  2. 提取出注册接口 URL、请求头（Headers）、加密密钥或签名算法（若有）。
  3. 编写一个独立函数或轻量脚本：每次生成一个新的 UUID4，调用该 API 获取最新节点配置（JSON）。

### 模块 2：sing-box 配置文件模板生成器 (`config_generator`)
根据 API 返回的节点出站结构，拼装标准的 `config.json`：
```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 20808
    }
  ],
  "outbounds": [
    {
      "type": "<从API提取的协议类型>",
      "tag": "proxy",
      "server": "<服务器IP/域名>",
      "server_port": 443,
      "...": "其余认证字段"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "auto_detect_interface": true
  }
}
```

### 模块 3：原生托盘客户端与进程树管理 (`tray_client`)
- **语言选项**：C# (.NET 4.8 / Core，可用系统自带 `csc.exe` 零环境编译) 或 Go (syso 图标单文件)。
- **进程树严密保护（核心重点）**：
  - 创建 Win32 **Job Object**，并将 `sing-box.exe` 关联至该 Job Object，设置 `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`。
  - 当托盘应用退出（无论正常退出、点击 Exit、还是被任务管理器杀死），Windows 操作系统保证连带强制终止 `sing-box.exe`，**绝无后台进程残留**。
- **系统代理控制**：
  - 调用 `wininet.dll` 中的 `InternetSetOption` 动态切换注册表 `ProxyEnable`（`127.0.0.1:20808`），断开时还原为 0。

---

## 5. 资源开销与指标对比

| 评价维度 | 废弃方案 (WSA + 桥接) | 原生化方案 (sing-box + Native Tray) |
|---|---|---|
| **磁盘占用** | **6.4 GB+**（不断膨胀） | **< 35 MB**（单 exe + sing-box.exe） |
| **内存开销** | **1.5 GB ~ 3 GB** (`vmmemWSA`) | **20 MB ~ 40 MB** |
| **启动耗时** | 60 ~ 120 秒（等待 VM 冷启动） | **< 0.5 秒**（瞬时就绪） |
| **后台稳定性** | 极差（WSA 闲置休眠导致死循环弹窗） | 极高（Windows 原生进程守护） |
| **残留进程** | 严重（adb、daemon、vmmem、apollgo） | **零残留**（Job Object 强绑定） |
| **系统侵入性** | 极高（需要 Hyper-V、UWP 框架） | 极低（便携单目录，即删即净） |

---

## 6. 落地执行路线图

1. **Step 1（接口解析）**：解包分析 `assets/index.android.bundle`，确定认证与节点下发接口。
2. **Step 2（内核引入）**：下载官方 Windows amd64 版本的 `sing-box.exe`，放入客户端目录。
3. **Step 3（客户端组装）**：实现轻量托盘 GUI，完成“连接 -> 获取试用节点 -> 启动 sing-box -> 开代理”及“断开/退出 -> 关代理 -> 杀内核”全流程。
4. **Step 4（清理旧债）**：安全卸载 WSA 关联数据包，彻底释放 C 盘 2.4 GB 空间。
