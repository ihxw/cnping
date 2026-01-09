# TCP Ping Test Script
# Read addresses from map.json and ping each node 10 times

param(
    [int]$PingCount = 10,
    [string]$MapFile = "map.json"
)

function Test-TcpPing {
    param(
        [string]$HostPort,
        [int]$Count = 10
    )
    
    $parts = $HostPort -split ':'
    if ($parts.Count -ne 2) {
        return @{
            Success = $false
            Error   = "Invalid address format"
        }
    }
    
    $hostname = $parts[0]
    $port = [int]$parts[1]
    
    $latencies = @()
    $successCount = 0
    
    for ($i = 1; $i -le $Count; $i++) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            $connectTask = $tcpClient.ConnectAsync($hostname, $port)
            if ($connectTask.Wait(5000)) {
                $stopwatch.Stop()
                $latency = $stopwatch.ElapsedMilliseconds
                $latencies += $latency
                $successCount++
                Write-Host "  [$i/$Count] $HostPort - ${latency}ms" -ForegroundColor Green
            }
            else {
                Write-Host "  [$i/$Count] $HostPort - Timeout" -ForegroundColor Red
            }
            
            $tcpClient.Close()
            $tcpClient.Dispose()
        }
        catch {
            Write-Host "  [$i/$Count] $HostPort - Failed" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    if ($latencies.Count -gt 0) {
        $avgLatency = ($latencies | Measure-Object -Average).Average
        $minLatency = ($latencies | Measure-Object -Minimum).Minimum
        $maxLatency = ($latencies | Measure-Object -Maximum).Maximum
        
        return @{
            Success     = $true
            Average     = [math]::Round($avgLatency, 2)
            Min         = $minLatency
            Max         = $maxLatency
            SuccessRate = [math]::Round(($successCount / $Count) * 100, 2)
        }
    }
    else {
        return @{
            Success = $false
            Error   = "All attempts failed"
        }
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "  TCP Ping Test Tool"
Write-Host "========================================"
Write-Host ""

if (-not (Test-Path $MapFile)) {
    Write-Host "Error: Cannot find file $MapFile" -ForegroundColor Red
    exit 1
}

try {
    $mapData = Get-Content $MapFile -Raw | ConvertFrom-Json
    Write-Host "Loaded $MapFile with $($mapData.Count) provinces" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Error: Cannot parse JSON file" -ForegroundColor Red
    exit 1
}

$results = @()

foreach ($province in $mapData) {
    Write-Host ""
    Write-Host "========== $($province.province) ==========" -ForegroundColor Yellow
    
    if ($province.unicom) {
        Write-Host ""
        Write-Host "[Unicom] Testing $($province.unicom)" -ForegroundColor Cyan
        $result = Test-TcpPing -HostPort $province.unicom -Count $PingCount
        
        if ($result.Success) {
            Write-Host "  Avg: $($result.Average)ms | Min: $($result.Min)ms | Max: $($result.Max)ms | Success: $($result.SuccessRate)%" -ForegroundColor Green
            $results += [PSCustomObject]@{
                Province    = $province.province
                ISP         = "Unicom"
                Address     = $province.unicom
                AvgLatency  = $result.Average
                MinLatency  = $result.Min
                MaxLatency  = $result.Max
                SuccessRate = $result.SuccessRate
            }
        }
    }
    
    if ($province.mobile) {
        Write-Host ""
        Write-Host "[Mobile] Testing $($province.mobile)" -ForegroundColor Cyan
        $result = Test-TcpPing -HostPort $province.mobile -Count $PingCount
        
        if ($result.Success) {
            Write-Host "  Avg: $($result.Average)ms | Min: $($result.Min)ms | Max: $($result.Max)ms | Success: $($result.SuccessRate)%" -ForegroundColor Green
            $results += [PSCustomObject]@{
                Province    = $province.province
                ISP         = "Mobile"
                Address     = $province.mobile
                AvgLatency  = $result.Average
                MinLatency  = $result.Min
                MaxLatency  = $result.Max
                SuccessRate = $result.SuccessRate
            }
        }
    }
    
    if ($province.telecom) {
        Write-Host ""
        Write-Host "[Telecom] Testing $($province.telecom)" -ForegroundColor Cyan
        $result = Test-TcpPing -HostPort $province.telecom -Count $PingCount
        
        if ($result.Success) {
            Write-Host "  Avg: $($result.Average)ms | Min: $($result.Min)ms | Max: $($result.Max)ms | Success: $($result.SuccessRate)%" -ForegroundColor Green
            $results += [PSCustomObject]@{
                Province    = $province.province
                ISP         = "Telecom"
                Address     = $province.telecom
                AvgLatency  = $result.Average
                MinLatency  = $result.Min
                MaxLatency  = $result.Max
                SuccessRate = $result.SuccessRate
            }
        }
    }
}

Write-Host ""
Write-Host ""
Write-Host "========================================"
Write-Host "  Test Summary"
Write-Host "========================================"
Write-Host ""

if ($results.Count -gt 0) {
    $sortedResults = $results | Sort-Object AvgLatency
    
    Write-Host "Top 10 Fastest Nodes:" -ForegroundColor Green
    $sortedResults | Select-Object -First 10 | Format-Table -AutoSize Province, ISP, Address, @{Label = "Avg(ms)"; Expression = { $_.AvgLatency } }, @{Label = "Success(%)"; Expression = { $_.SuccessRate } }
    
    Write-Host ""
    Write-Host "Top 10 Slowest Nodes:" -ForegroundColor Yellow
    $sortedResults | Select-Object -Last 10 | Format-Table -AutoSize Province, ISP, Address, @{Label = "Avg(ms)"; Expression = { $_.AvgLatency } }, @{Label = "Success(%)"; Expression = { $_.SuccessRate } }
    
    $csvFile = "tcp-ping-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
    Write-Host ""
    Write-Host "Results saved to: $csvFile" -ForegroundColor Green
}
else {
    Write-Host "No successful test results" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed!" -ForegroundColor Cyan
Write-Host ""
