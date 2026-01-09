# CNPing - TCP Ping 测试工具

一个用于测试中国各省份网络节点延迟的 TCP Ping 工具,支持 IPv4 和 IPv6 双栈测试。

## 快速开始

### 一键运行(Linux/macOS)

**完整测试(所有省份):**
```bash
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash
```

**测试模式(只测试前3个省份):**
```bash
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test
```

**自定义参数:**
```bash
# 每个节点 ping 20 次,超时 10 秒
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- -c 20 -t 10

# 测试模式 + 自定义参数
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test -c 5
```

> **说明:** 
> - 脚本会自动下载并在当前目录运行
> - 运行结束后自动清理临时文件
> - 只保留测试结果文件 `tcp-ping-results-*.md`

### 使用 wget

```bash
wget -qO- https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash
```

## 功能特性

- ✅ **双栈测试**: 自动测试 IPv4 和 IPv6
- ✅ **多运营商**: 支持联通、移动、电信三大运营商
- ✅ **自动生成报告**: Markdown 格式的测试报告
- ✅ **彩色终端输出**: 清晰易读的测试结果
- ✅ **跨平台**: 支持 Linux、macOS、Windows
- ✅ **多架构**: 支持 AMD64、ARM64、386

## 安装方法

### 方法1: 一键脚本(推荐)

**直接运行(推荐):**
```bash
# 完整测试
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash

# 测试模式
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test

# 自定义参数
curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- -c 20 -t 10
```

> **特点:**
> - ✅ 自动检测系统和架构
> - ✅ 自动下载对应版本
> - ✅ 在当前目录运行
> - ✅ 自动清理临时文件
> - ✅ 只保留测试结果

### 方法2: 下载二进制文件

从 [Releases](https://github.com/ihxw/cnping/releases) 页面下载对应平台的二进制文件:

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

### 方法3: 从源码编译

```bash
# 克隆仓库
git clone https://github.com/ihxw/cnping.git
cd cnping

# 编译
go build -o cnping main.go

# 运行
./cnping
```

## 使用方法

### 基本用法

```bash
# 测试所有省份(IPv4 + IPv6)
./cnping

# 测试模式(只测试前3个省份)
./cnping --test

# 自定义 ping 次数
./cnping -c 20

# 自定义超时时间
./cnping -t 10

# 指定输出文件名
./cnping -o result.md

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

## 输出示例

### 终端输出

```
========================================
  TCP Ping 测试工具
========================================

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
联通-IPv4    182        238        202.30     0.00
移动-IPv4    246        3304       773.20     0.00
电信-IPv4    180        334        209.30     0.00

=== IPv6 结果 ===

河北
运营商       最快(ms)   最慢(ms)   平均(ms)   丢包率(%)
----------   --------   --------   --------   ---------
联通-IPv6    -          -          -          100.00
移动-IPv6    -          -          -          100.00
电信-IPv6    -          -          -          100.00
```

### Markdown 输出

生成的 Markdown 文件包含两个部分:

**IPv4 测试结果:**

| 河北 | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%) |
|--------|----------|----------|----------|-----------|
| 联通-IPv4 | 182 | 238 | 202.30 | 0.00 |
| 移动-IPv4 | 246 | 3304 | 773.20 | 0.00 |
| 电信-IPv4 | 180 | 334 | 209.30 | 0.00 |

**IPv6 测试结果:**

| 河北 | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%) |
|--------|----------|----------|----------|-----------|
| 联通-IPv6 | - | - | - | 100.00 |
| 移动-IPv6 | - | - | - | 100.00 |
| 电信-IPv6 | - | - | - | 100.00 |

## 开发

### 编译全平台版本

**Linux/macOS:**
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

- Linux (AMD64, ARM64, 386)
- macOS (AMD64, ARM64)
- Windows (AMD64, 386)

## 数据文件

`map.json` 文件包含了各省份的测试节点地址,格式如下:

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

## 常见问题

**Q: IPv6 测试全部失败怎么办?**

A: 这可能是因为:
1. 您的网络不支持 IPv6
2. IPv6 节点地址不存在
3. 防火墙阻止了 IPv6 连接

这是正常现象,程序会正确显示连接失败的情况。

**Q: 如何只测试 IPv4?**

A: 目前程序会自动测试 IPv4 和 IPv6,如果只需要 IPv4 结果,可以在 Markdown 文件中只查看 IPv4 部分。

**Q: 可以自定义测试节点吗?**

A: 可以,修改 `map.json` 文件,添加或修改测试节点地址即可。

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request!

## 相关链接

- [GitHub 仓库](https://github.com/ihxw/cnping)
- [问题反馈](https://github.com/ihxw/cnping/issues)
- [发布页面](https://github.com/ihxw/cnping/releases)
