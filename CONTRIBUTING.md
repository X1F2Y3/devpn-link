# 贡献指南

本仓库是一份 **RFC（Request for Comments）** —— 内容是方案与论证，
不是实现代码。欢迎以两种方式参与。

## 方式一：讨论方案（最需要）

方案漏洞比文档笔误重要得多。如果你认为 `SOLUTION.md` 里的某条结论
站不住，请开 issue 说明：

- 你复现/验证了什么（解包结果、抓包、日志片段）
- 与文档哪一条冲突
- 你的结论

**证据 > 观点。** 没有证据的"我觉得不行"会被搁置。

## 方式二：提交实现

`README.md` 定义了目标架构与指标（磁盘 < 40MB · 内存 < 40MB ·
启动 < 0.5s · 退出零残留），语言不限（C# / Go / Rust 都合适）。

提交实现时请：

- 在 PR 描述里**逐条对照**目标架构与指标，给出实测数据
- 不要修改方案文档本身（方案与实现分开演进）
- 如需修正方案，单独开 PR 或 issue

## 不接受的贡献

- **打包的分发产物**：本项目不提供、也不托管已编译的代理二进制
  （`sing-box.exe` 本身请从其官方渠道获取）。
- **任何形式的付费节点 / 机场配置**：本仓库只讨论客户端架构。
- **绕过付费的内容**：方案的前提是「你已在合法范围内使用该服务」。

## 提交信息

Conventional Commits，祈使句：

```
docs(solution): correct the sing-box version reference
feat(client): add single-instance mutex
fix(tray): restore icon after explorer restart
```

## 许可

贡献即表示同意以 MIT 许可发布（见 [LICENSE](LICENSE)）。
