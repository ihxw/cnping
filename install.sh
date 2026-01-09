#!/bin/bash

# CNPing 一键下载运行脚本
# 自动检测系统架构,下载对应版本并运行
# 运行结束后自动清理临时文件,只保留测试结果

set -e

GITHUB_REPO="ihxw/cnping"
VERSION="latest"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "========================================="
echo "  CNPing 一键运行脚本"
echo "========================================="
echo -e "${NC}"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    else
        echo -e "${RED}不支持的操作系统: $OSTYPE${NC}"
        exit 1
    fi
}

# 检测架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        i386|i686)
            echo "386"
            ;;
        *)
            echo -e "${RED}不支持的架构: $arch${NC}"
            exit 1
            ;;
    esac
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    
    if command -v curl &> /dev/null; then
        curl -fsSL -o "$output" "$url"
    elif command -v wget &> /dev/null; then
        wget -q -O "$output" "$url"
    else
        echo -e "${RED}错误: 未找到 curl 或 wget${NC}"
        exit 1
    fi
}

# 清理函数
cleanup() {
    local exit_code=$?
    
    echo ""
    echo -e "${YELLOW}正在清理临时文件...${NC}"
    
    # 删除下载的二进制文件
    [ -f "cnping" ] && rm -f "cnping" && echo -e "${GREEN}  ✓ 已删除 cnping${NC}"
    
    # 删除下载的 map.json
    [ -f "map.json" ] && rm -f "map.json" && echo -e "${GREEN}  ✓ 已删除 map.json${NC}"
    
    # 删除临时文件
    [ -f ".cnping.tmp" ] && rm -f ".cnping.tmp"
    
    echo ""
    
    # 检查是否有结果文件
    if ls tcp-ping-results-*.md 1> /dev/null 2>&1; then
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}  测试完成!${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo ""
        echo -e "${CYAN}结果文件:${NC}"
        for file in tcp-ping-results-*.md; do
            echo -e "${GREEN}  ✓ $file${NC}"
        done
        echo ""
        echo -e "${YELLOW}提示: 结果文件已保存在当前目录${NC}"
    fi
    
    # 如果是错误退出,显示错误信息
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}程序异常退出 (退出码: $exit_code)${NC}"
    fi
    
    exit $exit_code
}

# 注册清理函数
trap cleanup EXIT INT TERM

# 主函数
main() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    local binary_name="cnping-${os}-${arch}"
    
    echo -e "${GREEN}检测到系统: ${os}/${arch}${NC}"
    echo ""
    
    # 下载 URL
    local download_url="https://github.com/${GITHUB_REPO}/releases/latest/download/${binary_name}"
    
    echo -e "${YELLOW}正在下载 cnping...${NC}"
    
    # 下载二进制文件到当前目录
    if download_file "$download_url" "cnping"; then
        echo -e "${GREEN}  ✓ cnping 下载成功${NC}"
    else
        echo -e "${RED}下载失败,尝试从备用源下载...${NC}"
        # 备用下载地址
        download_url="https://raw.githubusercontent.com/${GITHUB_REPO}/main/dist/${binary_name}"
        if ! download_file "$download_url" "cnping"; then
            echo -e "${RED}下载失败${NC}"
            exit 1
        fi
        echo -e "${GREEN}  ✓ cnping 下载成功${NC}"
    fi
    
    # 下载 map.json 到当前目录
    echo -e "${YELLOW}正在下载 map.json...${NC}"
    if download_file "https://raw.githubusercontent.com/${GITHUB_REPO}/main/map.json" "map.json"; then
        echo -e "${GREEN}  ✓ map.json 下载成功${NC}"
    else
        echo -e "${RED}下载 map.json 失败${NC}"
        exit 1
    fi
    
    # 添加执行权限
    chmod +x cnping
    
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}  开始测试...${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    
    # 运行程序
    ./cnping "$@"
    
    echo ""
}

# 显示帮助
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "用法: curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash"
    echo "      curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- [选项]"
    echo ""
    echo "选项:"
    echo "  --test          测试模式,只测试前3个省份"
    echo "  -c NUM          每个节点 ping 次数 (默认: 10)"
    echo "  -t NUM          超时时间(秒) (默认: 5)"
    echo "  -o FILE         输出文件名"
    echo "  -h, --help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  # 完整测试"
    echo "  curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash"
    echo ""
    echo "  # 测试模式(只测试前3个省份)"
    echo "  curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test"
    echo ""
    echo "  # 自定义参数"
    echo "  curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- -c 20 -t 10"
    echo ""
    echo "  # 测试模式 + 自定义参数"
    echo "  curl -fsSL https://raw.githubusercontent.com/ihxw/cnping/main/install.sh | bash -s -- --test -c 5"
    echo ""
    echo "说明:"
    echo "  - 程序会在当前目录下载并运行"
    echo "  - 运行结束后自动清理临时文件"
    echo "  - 只保留测试结果文件 (tcp-ping-results-*.md)"
    echo ""
    exit 0
fi

main "$@"
