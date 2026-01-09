#!/bin/bash

# TCP Ping Script for Linux
# Reads addresses from map.json and performs TCP ping tests
# Each node is pinged 10 times, and average latency is calculated


# Configuration
PING_COUNT=10
TIMEOUT=5
MAP_FILE="map.json"
MAP_URL="https://raw.githubusercontent.com/ihxw/cnping/main/map.json"
TEST_MODE=true  # Set to true to test only first 3 provinces
TEST_PROVINCE_COUNT=3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "centos"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to install dependencies
install_dependencies() {
    local deps=("$@")
    local os=$(detect_os)
    
    print_color "$YELLOW" "正在安装缺失的依赖: ${deps[*]}"
    
    case $os in
        ubuntu|debian)
            print_color "$BLUE" "使用 apt-get 安装..."
            if [ "$EUID" -ne 0 ]; then
                sudo apt-get update -qq && sudo apt-get install -y "${deps[@]}"
            else
                apt-get update -qq && apt-get install -y "${deps[@]}"
            fi
            ;;
        centos|rhel|fedora)
            print_color "$BLUE" "使用 yum 安装..."
            if [ "$EUID" -ne 0 ]; then
                sudo yum install -y "${deps[@]}"
            else
                yum install -y "${deps[@]}"
            fi
            ;;
        alpine)
            print_color "$BLUE" "使用 apk 安装..."
            if [ "$EUID" -ne 0 ]; then
                sudo apk add --no-cache "${deps[@]}"
            else
                apk add --no-cache "${deps[@]}"
            fi
            ;;
        arch)
            print_color "$BLUE" "使用 pacman 安装..."
            if [ "$EUID" -ne 0 ]; then
                sudo pacman -Sy --noconfirm "${deps[@]}"
            else
                pacman -Sy --noconfirm "${deps[@]}"
            fi
            ;;
        macos)
            print_color "$BLUE" "使用 brew 安装..."
            if ! command -v brew &> /dev/null; then
                print_color "$RED" "错误: 未找到 Homebrew,请先安装 Homebrew"
                return 1
            fi
            brew install "${deps[@]}"
            ;;
        *)
            print_color "$RED" "不支持的操作系统: $os"
            print_color "$YELLOW" "请手动安装以下依赖: ${deps[*]}"
            return 1
            ;;
    esac
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    local required_deps=("jq" "bc")
    
    print_color "$BLUE" "检查依赖..."
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
            print_color "$RED" "  ✗ $dep 未安装"
        else
            print_color "$GREEN" "  ✓ $dep 已安装"
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "发现缺失的依赖: ${missing_deps[*]}"
        print_color "$YELLOW" "正在自动安装..."
        echo ""
        
        if install_dependencies "${missing_deps[@]}"; then
            print_color "$GREEN" "依赖安装成功!"
            echo ""
            
            # 验证安装
            local install_failed=false
            for dep in "${missing_deps[@]}"; do
                if ! command -v "$dep" &> /dev/null; then
                    print_color "$RED" "  ✗ $dep 安装失败"
                    install_failed=true
                fi
            done
            
            if [ "$install_failed" = true ]; then
                print_color "$RED" "部分依赖安装失败,请手动安装"
                exit 1
            fi
        else
            print_color "$RED" "依赖安装失败,请手动安装:"
            print_color "$YELLOW" "  Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
            print_color "$YELLOW" "  CentOS/RHEL: sudo yum install ${missing_deps[*]}"
            print_color "$YELLOW" "  Alpine: sudo apk add ${missing_deps[*]}"
            print_color "$YELLOW" "  macOS: brew install ${missing_deps[*]}"
            exit 1
        fi
    fi
}

# Function to download map.json if not exists
download_map_file() {
    if [ ! -f "$MAP_FILE" ]; then
        print_color "$YELLOW" "正在从 GitHub 下载 map.json..."
        if command -v curl &> /dev/null; then
            curl -s -o "$MAP_FILE" "$MAP_URL"
        elif command -v wget &> /dev/null; then
            wget -q -O "$MAP_FILE" "$MAP_URL"
        else
            print_color "$RED" "错误: 未找到 curl 或 wget"
            exit 1
        fi
        print_color "$GREEN" "下载 map.json 成功"
    fi
}

# Function to perform TCP ping
tcp_ping() {
    local host=$1
    local port=$2
    local start_time
    local end_time
    local latency
    
    start_time=$(date +%s%3N)
    
    if timeout $TIMEOUT bash -c "exec 3<>/dev/tcp/$host/$port && exec 3>&-" 2>/dev/null; then
        end_time=$(date +%s%3N)
        latency=$((end_time - start_time))
        echo "$latency"
        return 0
    else
        echo "-1"
        return 1
    fi
}

# Function to test a single endpoint
test_endpoint() {
    local address=$1
    local province=$2
    local isp=$3
    
    # Parse host and port
    local host=$(echo "$address" | cut -d':' -f1)
    local port=$(echo "$address" | cut -d':' -f2)
    
    local latencies=()
    local success_count=0
    local fail_count=0
    
    # Show testing message
    echo -ne "  [$isp] 测试中..."
    
    for i in $(seq 1 $PING_COUNT); do
        latency=$(tcp_ping "$host" "$port")
        
        if [ "$latency" -ne -1 ]; then
            latencies+=($latency)
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
        
        # Show progress
        echo -ne "\r  [$isp] 测试中... $i/$PING_COUNT"
        sleep 0.1
    done
    
    # Clear progress line
    echo -ne "\r\033[K"
    
    # Calculate statistics
    if [ ${#latencies[@]} -gt 0 ]; then
        local sum=0
        local min=${latencies[0]}
        local max=${latencies[0]}
        
        for lat in "${latencies[@]}"; do
            sum=$((sum + lat))
            if [ $lat -lt $min ]; then
                min=$lat
            fi
            if [ $lat -gt $max ]; then
                max=$lat
            fi
        done
        
        local avg=$(echo "scale=2; $sum / ${#latencies[@]}" | bc)
        local loss_rate=$(echo "scale=2; $fail_count * 100 / $PING_COUNT" | bc)
        
        # Return results as a string
        echo "$province|$isp|$min|$max|$avg|$loss_rate"
    else
        local loss_rate="100.00"
        echo "$province|$isp|-|-|-|$loss_rate"
    fi
}

# Function to generate markdown report
generate_markdown_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    {
        echo "# TCP Ping 测试结果"
        echo ""
        echo "**生成时间:** $timestamp"
        echo ""
        
        # Read all data and group by province
        declare -A province_lines
        local provinces=()
        
        while IFS='|' read -r province isp min max avg loss; do
            # Track province order
            if [[ ! " ${provinces[@]} " =~ " ${province} " ]]; then
                provinces+=("$province")
            fi
            
            # Append line to province
            if [ -z "${province_lines[$province]}" ]; then
                province_lines[$province]="| $isp | $min | $max | $avg | $loss |"
            else
                province_lines[$province]="${province_lines[$province]}"$'\n'"| $isp | $min | $max | $avg | $loss |"
            fi
        done < "$RESULT_FILE"
        
        # Output tables for each province
        for province in "${provinces[@]}"; do
            echo ""
            echo "| $province | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%) |"
            echo "|--------|----------|----------|----------|-----------|"
            echo "${province_lines[$province]}"
        done
        
        echo ""
        echo "---"
        echo ""
        echo "**测试说明:**"
        echo "- 每个节点测试 $PING_COUNT 次"
        echo "- 超时时间: ${TIMEOUT}秒"
        echo "- 测试时间: $timestamp"
    } > "$MD_FILE"
}

# Function to display usage
usage() {
    cat << EOF
使用方法: $0 [选项]

选项:
    -c, --count NUM     每个节点 ping 次数 (默认: 10)
    -t, --timeout SEC   每次 ping 超时时间(秒) (默认: 5)
    -f, --file FILE     map.json 文件路径 (默认: map.json)
    --test              测试模式,只测试前 $TEST_PROVINCE_COUNT 个省份
    -h, --help          显示此帮助信息

示例:
    $0                  # 使用默认设置运行
    $0 -c 5             # 每个节点 ping 5 次
    $0 --test           # 测试模式,只测试前 3 个省份
    $0 -c 20 -t 10      # ping 20 次,超时 10 秒

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--count)
            PING_COUNT="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -f|--file)
            MAP_FILE="$2"
            shift 2
            ;;
        --test)
            TEST_MODE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_color "$RED" "未知选项: $1"
            usage
            ;;
    esac
done

# Main script
main() {
    print_color "$CYAN" "\n========================================"
    print_color "$CYAN" "  TCP Ping 测试工具"
    print_color "$CYAN" "========================================\n"
    
    # Check dependencies (silent mode)
    local missing_deps=()
    local required_deps=("jq" "bc")
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_color "$YELLOW" "正在安装缺失的依赖: ${missing_deps[*]}"
        if install_dependencies "${missing_deps[@]}"; then
            print_color "$GREEN" "依赖安装成功!\n"
        else
            print_color "$RED" "依赖安装失败,请手动安装"
            exit 1
        fi
    fi
    
    # Download map file if needed
    download_map_file
    
    # Check if map.json exists
    if [ ! -f "$MAP_FILE" ]; then
        print_color "$RED" "错误: 找不到文件 $MAP_FILE"
        exit 1
    fi
    
    # Create result files
    local timestamp=$(date +%Y%m%d-%H%M%S)
    RESULT_FILE="tcp-ping-results-${timestamp}.txt"
    MD_FILE="tcp-ping-results-${timestamp}.md"
    
    # Get total number of provinces
    local total_provinces=$(jq '. | length' "$MAP_FILE")
    
    if [ "$TEST_MODE" = true ]; then
        total_provinces=$TEST_PROVINCE_COUNT
        print_color "$YELLOW" "测试模式: 只测试前 $total_provinces 个省份"
    fi
    
    print_color "$GREEN" "开始测试 $total_provinces 个省份,每个节点 $PING_COUNT 次\n"
    
    # Clear result file
    > "$RESULT_FILE"
    
    # Read and process each province
    local province_count=0
    while IFS= read -r province_data; do
        province_count=$((province_count + 1))
        
        # Stop if in test mode and reached limit
        if [ "$TEST_MODE" = true ] && [ $province_count -gt $TEST_PROVINCE_COUNT ]; then
            break
        fi
        
        local province=$(echo "$province_data" | jq -r '.province')
        local unicom=$(echo "$province_data" | jq -r '.["联通"] // .unicom // empty')
        local mobile=$(echo "$province_data" | jq -r '.["移动"] // .mobile // empty')
        local telecom=$(echo "$province_data" | jq -r '.["电信"] // .telecom // empty')
        
        print_color "$YELLOW" "[$province_count/$total_provinces] $province"
        
        # Test each ISP and save results
        if [ -n "$unicom" ]; then
            result=$(test_endpoint "$unicom" "$province" "联通")
            echo "$result" >> "$RESULT_FILE"
        fi
        
        if [ -n "$mobile" ]; then
            result=$(test_endpoint "$mobile" "$province" "移动")
            echo "$result" >> "$RESULT_FILE"
        fi
        
        if [ -n "$telecom" ]; then
            result=$(test_endpoint "$telecom" "$province" "电信")
            echo "$result" >> "$RESULT_FILE"
        fi
    done < <(jq -c '.[]' "$MAP_FILE")
    
    # Display summary in terminal
    print_color "$CYAN" "\n========================================"
    print_color "$CYAN" "  测试结果"
    print_color "$CYAN" "========================================\n"
    
    # Display results grouped by province
    local current_province=""
    while IFS='|' read -r province isp min max avg loss; do
        if [ "$province" != "$current_province" ]; then
            if [ -n "$current_province" ]; then
                echo ""
            fi
            current_province="$province"
            print_color "$YELLOW" "$province"
            printf "%-8s %-10s %-10s %-10s %-10s\n" "运营商" "最快(ms)" "最慢(ms)" "平均(ms)" "丢包率(%)"
            printf "%-8s %-10s %-10s %-10s %-10s\n" "------" "--------" "--------" "--------" "---------"
        fi
        printf "%-8s %-10s %-10s %-10s %-10s\n" "$isp" "$min" "$max" "$avg" "$loss"
    done < "$RESULT_FILE"
    
    # Generate markdown report
    generate_markdown_report
    
    echo ""
    print_color "$GREEN" "\n结果已保存: $MD_FILE\n"
}

# Run main function
main
