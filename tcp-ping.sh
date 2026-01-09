#!/bin/bash

# TCP Ping Script for Linux
# Reads addresses from map.json and performs TCP ping tests
# Each node is pinged 10 times, and average latency is calculated


# Configuration
PING_COUNT=10
TIMEOUT=5
MAP_FILE="map.json"
MAP_URL="https://raw.githubusercontent.com/ihxw/cnping/main/map.json"

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
        print_color "$YELLOW" "Downloading map.json from GitHub..."
        if command -v curl &> /dev/null; then
            curl -s -o "$MAP_FILE" "$MAP_URL"
        elif command -v wget &> /dev/null; then
            wget -q -O "$MAP_FILE" "$MAP_URL"
        else
            print_color "$RED" "Error: Neither curl nor wget is available"
            exit 1
        fi
        print_color "$GREEN" "Downloaded map.json successfully"
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
    
    print_color "$CYAN" "\n[$isp] Testing $address"
    
    local latencies=()
    local success_count=0
    local fail_count=0
    
    for i in $(seq 1 $PING_COUNT); do
        latency=$(tcp_ping "$host" "$port")
        
        if [ "$latency" -ne -1 ]; then
            latencies+=($latency)
            success_count=$((success_count + 1))
            print_color "$GREEN" "  [$i/$PING_COUNT] $address - ${latency}ms"
        else
            fail_count=$((fail_count + 1))
            print_color "$RED" "  [$i/$PING_COUNT] $address - Failed/Timeout"
        fi
        
        # Small delay between pings
        sleep 0.1
    done
    
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
        local success_rate=$(echo "scale=2; $success_count * 100 / $PING_COUNT" | bc)
        
        print_color "$GREEN" "  Avg: ${avg}ms | Min: ${min}ms | Max: ${max}ms | Success: ${success_rate}%"
        
        # Output CSV line
        echo "$province,$isp,$address,$avg,$min,$max,$success_rate" >> "$RESULT_FILE"
    else
        print_color "$RED" "  All connection attempts failed"
    fi
}

# Function to generate TXT and Markdown reports
generate_reports() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Generate TXT report
    {
        echo "========================================"
        echo "  TCP Ping Test Results"
        echo "  Generated: $timestamp"
        echo "========================================"
        echo ""
        echo "Top 10 Fastest Nodes:"
        echo "----------------------------------------"
        (head -n 1 "$RESULT_FILE" && tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | head -n 10) | column -t -s','
        echo ""
        echo "Top 10 Slowest Nodes:"
        echo "----------------------------------------"
        (head -n 1 "$RESULT_FILE" && tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | tail -n 10) | column -t -s','
        echo ""
        echo "All Results (sorted by latency):"
        echo "----------------------------------------"
        (head -n 1 "$RESULT_FILE" && tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n) | column -t -s','
    } > "$TXT_FILE"
    
    # Generate Markdown report
    {
        echo "# TCP Ping Test Results"
        echo ""
        echo "**Generated:** $timestamp"
        echo ""
        echo "## Top 10 Fastest Nodes"
        echo ""
        echo "| Province | ISP | Address | Avg(ms) | Min(ms) | Max(ms) | Success(%) |"
        echo "|----------|-----|---------|---------|---------|---------|------------|"
        tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | head -n 10 | while IFS=',' read -r province isp address avg min max success; do
            echo "| $province | $isp | $address | $avg | $min | $max | $success |"
        done
        echo ""
        echo "## Top 10 Slowest Nodes"
        echo ""
        echo "| Province | ISP | Address | Avg(ms) | Min(ms) | Max(ms) | Success(%) |"
        echo "|----------|-----|---------|---------|---------|---------|------------|"
        tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | tail -n 10 | while IFS=',' read -r province isp address avg min max success; do
            echo "| $province | $isp | $address | $avg | $min | $max | $success |"
        done
        echo ""
        echo "## All Results (sorted by latency)"
        echo ""
        echo "| Province | ISP | Address | Avg(ms) | Min(ms) | Max(ms) | Success(%) |"
        echo "|----------|-----|---------|---------|---------|---------|------------|"
        tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | while IFS=',' read -r province isp address avg min max success; do
            echo "| $province | $isp | $address | $avg | $min | $max | $success |"
        done
        echo ""
        echo "---"
        echo ""
        echo "**Total Nodes Tested:** $(tail -n +2 "$RESULT_FILE" | wc -l)"
        echo ""
        # Calculate statistics
        local total_avg=$(tail -n +2 "$RESULT_FILE" | cut -d',' -f4 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
        echo "**Average Latency (all nodes):** ${total_avg}ms"
    } > "$MD_FILE"
}


# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -c, --count NUM     Number of pings per endpoint (default: 10)
    -t, --timeout SEC   Timeout for each ping in seconds (default: 5)
    -f, --file FILE     Path to map.json file (default: map.json)
    -h, --help          Display this help message

Examples:
    $0                  # Run with default settings
    $0 -c 5             # Ping each endpoint 5 times
    $0 -c 20 -t 10      # Ping 20 times with 10s timeout

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
        -h|--help)
            usage
            ;;
        *)
            print_color "$RED" "Unknown option: $1"
            usage
            ;;
    esac
done

# Main script
main() {
    print_color "$CYAN" "\n========================================"
    print_color "$CYAN" "  TCP Ping Test Tool"
    print_color "$CYAN" "========================================"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Download map file if needed
    download_map_file
    
    # Check if map.json exists
    if [ ! -f "$MAP_FILE" ]; then
        print_color "$RED" "Error: $MAP_FILE not found"
        exit 1
    fi
    
    # Create result files
    local timestamp=$(date +%Y%m%d-%H%M%S)
    RESULT_FILE="tcp-ping-results-${timestamp}.csv"
    TXT_FILE="tcp-ping-results-${timestamp}.txt"
    MD_FILE="tcp-ping-results-${timestamp}.md"
    echo "Province,ISP,Address,Avg(ms),Min(ms),Max(ms),Success(%)" > "$RESULT_FILE"

    
    # Get total number of provinces
    local total_provinces=$(jq '. | length' "$MAP_FILE")
    print_color "$GREEN" "Loaded $MAP_FILE with $total_provinces provinces"
    print_color "$YELLOW" "Testing each endpoint $PING_COUNT times with ${TIMEOUT}s timeout\n"
    
    # Read and process each province
    local province_count=0
    while IFS= read -r province_data; do
        province_count=$((province_count + 1))
        
        local province=$(echo "$province_data" | jq -r '.province')
        local unicom=$(echo "$province_data" | jq -r '.unicom // empty')
        local mobile=$(echo "$province_data" | jq -r '.mobile // empty')
        local telecom=$(echo "$province_data" | jq -r '.telecom // empty')
        
        print_color "$YELLOW" "\n========== [$province_count/$total_provinces] $province =========="
        
        # Test Unicom
        if [ -n "$unicom" ]; then
            test_endpoint "$unicom" "$province" "Unicom"
        fi
        
        # Test Mobile
        if [ -n "$mobile" ]; then
            test_endpoint "$mobile" "$province" "Mobile"
        fi
        
        # Test Telecom
        if [ -n "$telecom" ]; then
            test_endpoint "$telecom" "$province" "Telecom"
        fi
    done < <(jq -c '.[]' "$MAP_FILE")
    
    # Display summary
    print_color "$CYAN" "\n\n========================================"
    print_color "$CYAN" "  Test Summary"
    print_color "$CYAN" "========================================"
    echo ""
    
    # Sort results and display top/bottom 10
    if [ -f "$RESULT_FILE" ] && [ $(wc -l < "$RESULT_FILE") -gt 1 ]; then
        print_color "$GREEN" "Top 10 Fastest Nodes:"
        echo ""
        (head -n 1 "$RESULT_FILE" && tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | head -n 10) | column -t -s','
        
        echo ""
        print_color "$YELLOW" "Top 10 Slowest Nodes:"
        echo ""
        (head -n 1 "$RESULT_FILE" && tail -n +2 "$RESULT_FILE" | sort -t',' -k4 -n | tail -n 10) | column -t -s','
        
        # Generate TXT and Markdown reports
        generate_reports
        
        echo ""
        print_color "$GREEN" "Results saved to:"
        print_color "$GREEN" "  - CSV: $RESULT_FILE"
        print_color "$GREEN" "  - TXT: $TXT_FILE"
        print_color "$GREEN" "  - Markdown: $MD_FILE"
    else
        print_color "$RED" "No successful test results"
    fi
    
    echo ""
    print_color "$CYAN" "Test completed!"
    echo ""
}

# Run main function
main
