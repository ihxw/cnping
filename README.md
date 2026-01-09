# CNPing - TCP Ping 测试工具

一个用于测试中国各省份网络节点延迟的 TCP Ping 工具,支持 IPv4 和 IPv6 双栈测试。

[![CI](https://github.com/ihxw/cnping/actions/workflows/ci.yml/badge.svg)](https://github.com/ihxw/cnping/actions/workflows/ci.yml)
[![Release](https://github.com/ihxw/cnping/actions/workflows/release.yml/badge.svg)](https://github.com/ihxw/cnping/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org)

## ✨ 特性

- 🌐 **双栈测试**: 自动测试 IPv4 和 IPv6 网络
- 📊 **多运营商**: 支持联通、移动、电信三大运营商
- 📝 **自动报告**: 生成 Markdown 格式的测试报告
- 🎨 **彩色输出**: 清晰易读的终端显示
- 🚀 **跨平台**: 支持 Linux、macOS、Windows
- 💻 **多架构**: 支持 AMD64、ARM64、386
- 🧹 **自动清理**: 测试完成后自动清理临时文件
- 📍 **智能保存**: 结果保存到脚本调用目录

## 🚀 快速开始

### 一键运行 (推荐)

**Linux / macOS:**

```bash
# 完整测试 (所有省份 IPv4 + IPv6)
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash

# 测试模式 (只测试前3个省份)
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test

# 自定义参数
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- -c 20 -t 10
```

**使用 wget:**

```bash
wget -qO- https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash
```

> **工作原理:**
> - 自动检测系统和架构
> - 在系统临时目录中下载并运行
> - 测试完成后自动清理所有临时文件
> - 结果文件保存到当前目录
> - 显示结果文件的完整路径

## 📦 安装方法

### 方法 1: 一键脚本 (推荐)

适合快速测试,无需安装:

```bash
# 完整测试
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash

# 测试模式
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test

# 自定义参数: 每个节点 ping 20 次,超时 10 秒
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- -c 20 -t 10
```

### 方法 2: 下载二进制文件

从 [Releases](https://github.com/ihxw/cnping/releases) 下载对应平台的二进制文件:

**Linux AMD64:**
```bash
wget https://github.com/ihxw/cnping/releases/latest/download/cnping-linux-amd64
chmod +x cnping-linux-amd64
./cnping-linux-amd64
```

**macOS ARM64 (Apple Silicon):**
```bash
wget https://github.com/ihxw/cnping/releases/latest/download/cnping-darwin-arm64
chmod +x cnping-darwin-arm64
./cnping-darwin-arm64
```

**Windows:**

下载 `cnping-windows-amd64.exe` 并双击运行,或在命令行中运行:
```cmd
cnping-windows-amd64.exe
```

### 方法 3: 从源码编译

```bash
# 克隆仓库
git clone https://github.com/ihxw/cnping.git
cd cnping

# 编译
go build -o cnping main.go

# 运行
./cnping
```

## 📖 使用说明

### 基本用法

```bash
# 完整测试 (所有省份 IPv4 + IPv6)
./cnping

# 测试模式 (只测试前3个省份)
./cnping --test

# 自定义 ping 次数
./cnping -c 20

# 自定义超时时间
./cnping -t 10

# 指定输出文件名
./cnping -o my-result.md

# 组合使用
./cnping --test -c 5 -t 3
```

### 命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-c, --count` | 每个节点 ping 次数 | 10 |
| `-t, --timeout` | 超时时间(秒) | 5 |
| `-f, --file` | map.json 文件路径 | map.json |
| `-o, --output` | 输出 Markdown 文件名 | 自动生成 |
| `--test` | 测试模式,只测试前3个省份 | false |
| `-h, --help` | 显示帮助信息 | - |

## 📊 输出示例

### 终端输出

```
=========================================
  TCP Ping 测试工具
=========================================

开始测试 30 个省份,每个节点 10 次

========== IPv4 测试 ==========

[1/30] 河北
  [联通-IPv4] 测试中... 10/10
  [移动-IPv4] 测试中... 10/10
  [电信-IPv4] 测试中... 10/10

========== IPv6 测试 ==========

[1/30] 河北
  [联通-IPv6] 测试中... 10/10
  [移动-IPv6] 测试中... 10/10
  [电信-IPv6] 测试中... 10/10

========================================
  测试结果
========================================

=== IPv4 结果 ===

河北
运营商       最快(ms)   最慢(ms)   平均(ms)   丢包率(%)
----------   --------   --------   --------   ---------
联通-IPv4    63         123        73.30      0.00
移动-IPv4    92         330        125.00     0.00
电信-IPv4    58         1088       171.60     0.00

=== IPv6 结果 ===

河北
运营商       最快(ms)   最慢(ms)   平均(ms)   丢包率(%)
----------   --------   --------   --------   ---------
联通-IPv6    75         1105       390.90     0.00
移动-IPv6    107        125        113.40     0.00
电信-IPv6    134        1174       590.89     10.00

结果已保存: tcp-ping-results-20260109-150734.md
```

### Markdown 输出

生成的 Markdown 文件包含两个部分:

#### IPv4 测试结果

| 河北 | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%) |
|--------|----------|----------|----------|-----------|
| 联通-IPv4 | 63 | 123 | 73.30 | 0.00 |
| 移动-IPv4 | 92 | 330 | 125.00 | 0.00 |
| 电信-IPv4 | 58 | 1088 | 171.60 | 0.00 |

#### IPv6 测试结果

| 河北 | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%) |
|--------|----------|----------|----------|-----------|
| 联通-IPv6 | 75 | 1105 | 390.90 | 0.00 |
| 移动-IPv6 | 107 | 125 | 113.40 | 0.00 |
| 电信-IPv6 | 134 | 1174 | 590.89 | 10.00 |

## 🛠️ 开发

### 编译全平台版本

**Linux / macOS:**
```bash
chmod +x build.sh
./build.sh
```

**Windows:**
```cmd
build.bat
```

编译后的文件将保存在 `dist/` 目录中。

### 支持的平台

| 操作系统 | 架构 | 文件名 |
|---------|------|--------|
| Linux | AMD64 | cnping-linux-amd64 |
| Linux | ARM64 | cnping-linux-arm64 |
| Linux | 386 | cnping-linux-386 |
| macOS | AMD64 | cnping-darwin-amd64 |
| macOS | ARM64 | cnping-darwin-arm64 |
| Windows | AMD64 | cnping-windows-amd64.exe |
| Windows | 386 | cnping-windows-386.exe |

## 📁 数据文件

`map.json` 文件包含了各省份的测试节点地址:

```json
[
  {
    "province": "河北",
    "联通": "he-cu-v4.ip.zstaticcdn.com:80",
    "移动": "he-cm-v4.ip.zstaticcdn.com:80",
    "电信": "he-ct-v4.ip.zstaticcdn.com:80"
  }
]
```

程序会自动将 `-v4.ip` 替换为 `-v6.ip` 进行 IPv6 测试。

## ❓ 常见问题

### Q: IPv6 测试全部失败怎么办?

A: 这可能是因为:
- 您的网络不支持 IPv6
- IPv6 节点地址不存在或未配置
- 防火墙阻止了 IPv6 连接

这是正常现象,程序会正确显示连接失败的情况。

### Q: 如何只测试 IPv4?

A: 目前程序会自动测试 IPv4 和 IPv6。如果只需要 IPv4 结果,可以在生成的 Markdown 文件中只查看 IPv4 部分。

### Q: 可以自定义测试节点吗?

A: 可以,修改 `map.json` 文件,添加或修改测试节点地址即可。

### Q: 测试结果保存在哪里?

A: 
- 使用一键脚本时,结果保存在**脚本调用目录**(即你运行 curl 命令的目录)
- 直接运行二进制文件时,结果保存在**当前目录**
- 文件名格式: `tcp-ping-results-YYYYMMDD-HHMMSS.md`

### Q: 临时文件会保留吗?

A: 不会。使用一键脚本时:
- 程序在系统临时目录中运行
- 测试完成后自动清理所有临时文件
- 只保留测试结果文件

## 🔧 技术细节

### 工作原理

1. **地址解析**: 从 `map.json` 读取测试节点地址
2. **IPv4 测试**: 使用 TCP 连接测试 IPv4 节点
3. **IPv6 测试**: 自动替换地址为 IPv6 并测试
4. **延迟计算**: 记录每次连接的时间,计算平均值
5. **结果生成**: 按省份分组,生成 Markdown 报告

### 依赖项

- Go 1.21+ (仅编译时需要)
- 无运行时依赖 (编译后的二进制文件可独立运行)

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 🔗 相关链接

- [GitHub 仓库](https://github.com/ihxw/cnping)
- [问题反馈](https://github.com/ihxw/cnping/issues)
- [发布页面](https://github.com/ihxw/cnping/releases)

## 📝 更新日志

### v1.0.0 (2026-01-09)

- ✅ 支持 IPv4 和 IPv6 双栈测试
- ✅ 支持三大运营商节点测试
- ✅ 自动生成 Markdown 报告
- ✅ 跨平台支持 (Linux, macOS, Windows)
- ✅ 多架构支持 (AMD64, ARM64, 386)
- ✅ 一键运行脚本
- ✅ 自动清理临时文件
- ✅ 彩色终端输出

---

**Made with ❤️ by [ihxw](https://github.com/ihxw)**
