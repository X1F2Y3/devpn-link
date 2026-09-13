# DeVPN Windows Native Client

> **DeVPN PC 端原生化重构方案** —— 彻底淘汰 WSA / 安卓虚拟机套娃架构，以原生 Windows 方式运行 DeVPN 代理服务。

![LICENSE](https://img.shields.io/github/license/X1F2Y3/devpn-link?style=flat-square) ![platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue?style=flat-square)

---

## 为什么有这个仓库

DeVPN（`com.desafa.devpn`）是 Android 版 VPN 应用，没有 Windows 客户端。此前仓库中的 WSA + adb 桥接方案：

- **磁盘爆炸**：WSA 在 C 盘运行时缓存 2.4GB+，加系统镜像整体占用 6.4GB+，曾占满硬盘
- **病毒式弹窗**：多个脚本死循环检测 WSA 端口，失败就反复拉起 WSA 窗口
- **链路脆弱**：adb / 代理端口三套脚本互相冲突，UI 自动点击依赖硬编码坐标

本仓库提供**彻底的重构方案**。详见 [SOLUTION.md](./SOLUTION.md)。

---

## 核心发现（逆向审计结论）

解包 `devpn.apk` 确认：

- **前端**：React Native（`assets/index.android.bundle`）
- **VPN 内核**：开源通用代理内核 **sing-box**（`assets/singbox/geoip-cn.srs`、`AdGuardSDNSFilterSingBox.srs` 等）
- **协议**：标准通用代理协议（VLESS / Shadowsocks / Hysteria / WireGuard），无私有加密驱动
- **试用机制**：移动端"清数据重置 7 天"证明认证仅依赖客户端生成的随机 `DeviceID / UUID`，向注册 API 发送新 ID 即可换取节点配置

**结论**：无需 Android 模拟器，直接用 Windows 原生 `sing-box.exe` 即可。

---

## 目标架构

```
+-----------------------------------------------------------+
|              DeVPN Native Client (原生轻量托盘程序)        |
|   - 单实例互斥                                            |
|   - 托盘图标：已连接(绿) / 未连接(灰)                     |
|   - 设备 ID 自动刷新 / 节点获取器                         |
|   - Windows 系统代理 (WinINet) / TUN 生命周期管理         |
+-----------------------------+-----------------------------+
                              | (Job Object 强绑定子进程)
                              v
+-----------------------------------------------------------+
|         sing-box.exe (官方 Windows 原生内核, ~20MB)       |
|   入站: mixed (HTTP/SOCKS5 127.0.0.1:20808) 或 TUN 网卡   |
|   出站: DeVPN 代理节点                                    |
+-----------------------------+-----------------------------+
                              |
                              v
                        Internet 出口
```

**指标要求**：磁盘 < 40MB · 内存 < 40MB · 启动 < 0.5s · 退出零残留。

---

## 文档导航

| 文档 | 内容 |
| --- | --- |
| [`SOLUTION.md`](./SOLUTION.md) | 完整技术规范：根因分析、逆向结论、模块设计、落地路线图 |

---

## 贡献

本仓库为 RFC 性质。欢迎基于 `SOLUTION.md` 提交实现代码（C# / Go / Rust）。

## 免责声明

本仓库仅用于个人学习与网络调试。请遵守当地法律法规与所使用服务的条款。