@echo off
REM 全平台编译脚本 (Windows 版本)
REM 编译 cnping 为多个平台的二进制文件

setlocal enabledelayedexpansion

set VERSION=1.0.0
set OUTPUT_DIR=dist

echo =========================================
echo   CNPing 全平台编译脚本
echo   版本: %VERSION%
echo =========================================
echo.

REM 创建输出目录
if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%

REM Linux AMD64
echo 编译 linux/amd64...
set GOOS=linux
set GOARCH=amd64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-linux-amd64 main.go
if %errorlevel% equ 0 (
    echo   √ cnping-linux-amd64 编译成功
) else (
    echo   × cnping-linux-amd64 编译失败
)
echo.

REM Linux ARM64
echo 编译 linux/arm64...
set GOOS=linux
set GOARCH=arm64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-linux-arm64 main.go
if %errorlevel% equ 0 (
    echo   √ cnping-linux-arm64 编译成功
) else (
    echo   × cnping-linux-arm64 编译失败
)
echo.

REM Linux 386
echo 编译 linux/386...
set GOOS=linux
set GOARCH=386
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-linux-386 main.go
if %errorlevel% equ 0 (
    echo   √ cnping-linux-386 编译成功
) else (
    echo   × cnping-linux-386 编译失败
)
echo.

REM macOS AMD64
echo 编译 darwin/amd64...
set GOOS=darwin
set GOARCH=amd64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-darwin-amd64 main.go
if %errorlevel% equ 0 (
    echo   √ cnping-darwin-amd64 编译成功
) else (
    echo   × cnping-darwin-amd64 编译失败
)
echo.

REM macOS ARM64
echo 编译 darwin/arm64...
set GOOS=darwin
set GOARCH=arm64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-darwin-arm64 main.go
if %errorlevel% equ 0 (
    echo   √ cnping-darwin-arm64 编译成功
) else (
    echo   × cnping-darwin-arm64 编译失败
)
echo.

REM Windows AMD64
echo 编译 windows/amd64...
set GOOS=windows
set GOARCH=amd64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-windows-amd64.exe main.go
if %errorlevel% equ 0 (
    echo   √ cnping-windows-amd64.exe 编译成功
) else (
    echo   × cnping-windows-amd64.exe 编译失败
)
echo.

REM Windows 386
echo 编译 windows/386...
set GOOS=windows
set GOARCH=386
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-windows-386.exe main.go
if %errorlevel% equ 0 (
    echo   √ cnping-windows-386.exe 编译成功
) else (
    echo   × cnping-windows-386.exe 编译失败
)
echo.

echo =========================================
echo 编译完成! 输出目录: %OUTPUT_DIR%
echo =========================================
echo.

REM 列出所有编译的文件
echo 编译的文件列表:
dir %OUTPUT_DIR%

endlocal
