# Changelog

本仓库所有值得记录的变更都在这里。格式遵循
[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

> 本仓库目前是 **RFC（技术提案）阶段**：仓库里是方案文档，不含实现代码。
> 因此变更主要记录文档与结论的演进。

## [Unreleased]

### 新增
- `CONTRIBUTING.md`、`SECURITY.md`、`CHANGELOG.md`、`.gitattributes`，
  补齐仓库规范件。
- 仓库 About 描述（此前为空）。

## [0.1.0] — 2026-09

### 新增
- `README.md` —— 问题陈述 + 核心发现摘要 + 目标架构。
- `SOLUTION.md` —— 完整技术规范：根因分析、`devpn.apk` 逆向结论、
  模块设计、落地路线图。
- `.gitignore`、`LICENSE`（MIT）。

### 结论
- DeVPN（`com.desafa.devpn`）移动端 VPN 内核为开源 **sing-box**，
  协议为标准通用代理协议，**无私有加密驱动**。
- 因此无需 WSA / 安卓模拟器，Windows 原生 `sing-box.exe` 即可承接。
- 试用机制依赖客户端生成的随机 `DeviceID / UUID`，非服务端强绑定。

[Unreleased]: https://github.com/X1F2Y3/devpn-link/commits/main
[0.1.0]: https://github.com/X1F2Y3/devpn-link/commits/main
