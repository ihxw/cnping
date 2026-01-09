#!/bin/bash

# 全平台编译脚本
# 编译 cnping 为多个平台的二进制文件

VERSION="1.0.0"
OUTPUT_DIR="dist"

echo "========================================="
echo "  CNPing 全平台编译脚本"
echo "  版本: $VERSION"
echo "========================================="
echo ""

# 创建输出目录
mkdir -p $OUTPUT_DIR

# 定义要编译的平台
platforms=(
    "linux/amd64"
    "linux/arm64"
    "linux/386"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
    "windows/386"
)

# 编译每个平台
for platform in "${platforms[@]}"; do
    IFS='/' read -r GOOS GOARCH <<< "$platform"
    
    output_name="cnping-${GOOS}-${GOARCH}"
    
    if [ "$GOOS" = "windows" ]; then
        output_name="${output_name}.exe"
    fi
    
    echo "编译 ${GOOS}/${GOARCH}..."
    
    GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w" -o "${OUTPUT_DIR}/${output_name}" main.go
    
    if [ $? -eq 0 ]; then
        echo "  ✓ ${output_name} 编译成功"
        
        # 计算文件大小
        if [ "$GOOS" = "darwin" ] || [ "$GOOS" = "linux" ]; then
            size=$(ls -lh "${OUTPUT_DIR}/${output_name}" | awk '{print $5}')
        else
            size=$(du -h "${OUTPUT_DIR}/${output_name}" | cut -f1)
        fi
        echo "    大小: ${size}"
    else
        echo "  ✗ ${output_name} 编译失败"
    fi
    echo ""
done

echo "========================================="
echo "编译完成! 输出目录: ${OUTPUT_DIR}"
echo "========================================="
echo ""

# 列出所有编译的文件
echo "编译的文件列表:"
ls -lh ${OUTPUT_DIR}/
