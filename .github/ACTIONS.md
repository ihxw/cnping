# GitHub Actions 使用说明

本项目使用 GitHub Actions 实现自动化编译和发布。

## 工作流说明

### 1. CI 工作流 (`.github/workflows/ci.yml`)

**触发条件:**
- 推送到 `main` 分支
- 创建 Pull Request 到 `main` 分支

**功能:**
- 代码格式检查 (`gofmt`)
- 编译检查
- 跨平台编译测试
- 代码质量检查 (`golangci-lint`)

### 2. Release 工作流 (`.github/workflows/release.yml`)

**触发条件:**
- 推送 tag (格式: `v*`,例如 `v1.0.0`)
- 手动触发 (workflow_dispatch)

**功能:**
- 编译全平台二进制文件 (7个平台)
- 生成 SHA256 校验和
- 自动创建 GitHub Release
- 上传编译产物

## 如何发布新版本

### 方法 1: 使用 Git Tag (推荐)

```bash
# 1. 确保代码已提交
git add .
git commit -m "Release v1.0.0"

# 2. 创建并推送 tag
git tag v1.0.0
git push origin v1.0.0

# 3. GitHub Actions 会自动:
#    - 编译全平台二进制文件
#    - 创建 Release
#    - 上传文件
```

### 方法 2: 手动触发

1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择 `Build and Release` 工作流
4. 点击 `Run workflow`
5. 选择分支并运行

## 编译产物

每次发布会生成以下文件:

| 文件名 | 平台 | 架构 | 大小 |
|--------|------|------|------|
| cnping-linux-amd64 | Linux | AMD64 | ~2.5MB |
| cnping-linux-arm64 | Linux | ARM64 | ~2.5MB |
| cnping-linux-386 | Linux | 386 | ~2.4MB |
| cnping-darwin-amd64 | macOS | AMD64 | ~2.6MB |
| cnping-darwin-arm64 | macOS | ARM64 | ~2.6MB |
| cnping-windows-amd64.exe | Windows | AMD64 | ~2.7MB |
| cnping-windows-386.exe | Windows | 386 | ~2.5MB |
| checksums.txt | - | - | ~1KB |

## Release 说明

Release 会自动包含:

- 所有平台的二进制文件
- SHA256 校验和文件
- 下载说明
- 使用方法
- 一键运行命令

## 版本号规范

建议使用语义化版本号:

- `v1.0.0` - 主版本.次版本.修订号
- `v1.0.0-beta.1` - 预发布版本
- `v1.0.0-rc.1` - 候选版本

## 故障排查

### 编译失败

检查:
- Go 版本是否正确 (需要 1.21+)
- 代码是否有语法错误
- 依赖是否正确

### Release 创建失败

检查:
- Tag 格式是否正确 (必须以 `v` 开头)
- GitHub Token 权限是否足够
- 是否有同名 Release 已存在

## 本地测试

在推送 tag 之前,可以本地测试编译:

```bash
# Windows
.\build.bat

# Linux/macOS
chmod +x build.sh
./build.sh
```

编译产物会保存在 `dist/` 目录中。

## 注意事项

1. **Tag 命名**: 必须以 `v` 开头,例如 `v1.0.0`
2. **权限**: 确保仓库有 `contents: write` 权限
3. **清理**: 旧的 Release 需要手动删除
4. **Artifacts**: 编译产物会保留 30 天

## 相关链接

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Go 交叉编译](https://golang.org/doc/install/source#environment)
- [语义化版本](https://semver.org/lang/zh-CN/)
