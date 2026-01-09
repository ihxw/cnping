@echo off
REM Cross-platform Build Script (Windows)
REM Build cnping for multiple platforms

setlocal enabledelayedexpansion

set VERSION=1.0.0
set OUTPUT_DIR=dist

echo =========================================
echo   CNPing Cross-Platform Build Script
echo   Version: %VERSION%
echo =========================================
echo.

REM Create output directory
if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%

REM Linux AMD64
echo Building linux/amd64...
set GOOS=linux
set GOARCH=amd64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-linux-amd64 main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-linux-amd64
) else (
    echo   [FAIL] cnping-linux-amd64
)
echo.

REM Linux ARM64
echo Building linux/arm64...
set GOOS=linux
set GOARCH=arm64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-linux-arm64 main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-linux-arm64
) else (
    echo   [FAIL] cnping-linux-arm64
)
echo.

REM Linux 386
echo Building linux/386...
set GOOS=linux
set GOARCH=386
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-linux-386 main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-linux-386
) else (
    echo   [FAIL] cnping-linux-386
)
echo.

REM macOS AMD64
echo Building darwin/amd64...
set GOOS=darwin
set GOARCH=amd64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-darwin-amd64 main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-darwin-amd64
) else (
    echo   [FAIL] cnping-darwin-amd64
)
echo.

REM macOS ARM64
echo Building darwin/arm64...
set GOOS=darwin
set GOARCH=arm64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-darwin-arm64 main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-darwin-arm64
) else (
    echo   [FAIL] cnping-darwin-arm64
)
echo.

REM Windows AMD64
echo Building windows/amd64...
set GOOS=windows
set GOARCH=amd64
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-windows-amd64.exe main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-windows-amd64.exe
) else (
    echo   [FAIL] cnping-windows-amd64.exe
)
echo.

REM Windows 386
echo Building windows/386...
set GOOS=windows
set GOARCH=386
go build -ldflags="-s -w" -o %OUTPUT_DIR%/cnping-windows-386.exe main.go
if %errorlevel% equ 0 (
    echo   [OK] cnping-windows-386.exe
) else (
    echo   [FAIL] cnping-windows-386.exe
)
echo.

echo =========================================
echo Build Complete! Output: %OUTPUT_DIR%
echo =========================================
echo.

REM List all compiled files
echo Compiled files:
dir %OUTPUT_DIR%

endlocal
