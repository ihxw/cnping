package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net"
	"os"
	"strings"
	"time"
)

// Province 省份结构
type Province struct {
	Province string `json:"province"`
	Unicom   string `json:"联通"`
	Mobile   string `json:"移动"`
	Telecom  string `json:"电信"`
}

// TestResult 测试结果
type TestResult struct {
	Province   string
	ISP        string
	MinLatency int64
	MaxLatency int64
	AvgLatency float64
	LossRate   float64
}

// ProvinceResults 按省份分组的结果
type ProvinceResults struct {
	Province string
	Results  []TestResult
}

const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
	colorCyan   = "\033[36m"
)

var (
	pingCount  = flag.Int("c", 10, "每个节点 ping 次数")
	timeout    = flag.Int("t", 5, "超时时间(秒)")
	mapFile    = flag.String("f", "map.json", "map.json 文件路径")
	testMode   = flag.Bool("test", false, "测试模式,只测试前3个省份")
	outputFile = flag.String("o", "", "输出 Markdown 文件名(默认自动生成)")
)

func main() {
	flag.Parse()

	fmt.Printf("%s\n========================================\n", colorCyan)
	fmt.Printf("  TCP Ping 测试工具\n")
	fmt.Printf("========================================\n%s\n", colorReset)

	// 读取 map.json
	data, err := ioutil.ReadFile(*mapFile)
	if err != nil {
		fmt.Printf("%s错误: 无法读取文件 %s: %v%s\n", colorRed, *mapFile, err, colorReset)
		os.Exit(1)
	}

	var provinces []Province
	if err := json.Unmarshal(data, &provinces); err != nil {
		fmt.Printf("%s错误: 无法解析 JSON: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	// 测试模式
	if *testMode && len(provinces) > 3 {
		provinces = provinces[:3]
		fmt.Printf("%s测试模式: 只测试前 3 个省份%s\n", colorYellow, colorReset)
	}

	fmt.Printf("%s开始测试 %d 个省份,每个节点 %d 次%s\n\n", colorGreen, len(provinces), *pingCount, colorReset)

	// 执行 IPv4 测试
	fmt.Printf("%s========== IPv4 测试 ==========%s\n\n", colorCyan, colorReset)
	var ipv4Results []ProvinceResults
	for i, prov := range provinces {
		fmt.Printf("%s[%d/%d] %s%s\n", colorYellow, i+1, len(provinces), prov.Province, colorReset)

		var provResults []TestResult

		// 测试联通
		if prov.Unicom != "" {
			result := testEndpoint(prov.Unicom, prov.Province, "联通", "IPv4")
			provResults = append(provResults, result)
		}

		// 测试移动
		if prov.Mobile != "" {
			result := testEndpoint(prov.Mobile, prov.Province, "移动", "IPv4")
			provResults = append(provResults, result)
		}

		// 测试电信
		if prov.Telecom != "" {
			result := testEndpoint(prov.Telecom, prov.Province, "电信", "IPv4")
			provResults = append(provResults, result)
		}

		ipv4Results = append(ipv4Results, ProvinceResults{
			Province: prov.Province,
			Results:  provResults,
		})
	}

	// 执行 IPv6 测试
	fmt.Printf("\n%s========== IPv6 测试 ==========%s\n\n", colorCyan, colorReset)
	var ipv6Results []ProvinceResults
	for i, prov := range provinces {
		fmt.Printf("%s[%d/%d] %s%s\n", colorYellow, i+1, len(provinces), prov.Province, colorReset)

		var provResults []TestResult

		// 将 v4 地址转换为 v6 地址
		unicomV6 := strings.Replace(prov.Unicom, "-v4.ip", "-v6.ip", 1)
		mobileV6 := strings.Replace(prov.Mobile, "-v4.ip", "-v6.ip", 1)
		telecomV6 := strings.Replace(prov.Telecom, "-v4.ip", "-v6.ip", 1)

		// 测试联通
		if prov.Unicom != "" {
			result := testEndpoint(unicomV6, prov.Province, "联通", "IPv6")
			provResults = append(provResults, result)
		}

		// 测试移动
		if prov.Mobile != "" {
			result := testEndpoint(mobileV6, prov.Province, "移动", "IPv6")
			provResults = append(provResults, result)
		}

		// 测试电信
		if prov.Telecom != "" {
			result := testEndpoint(telecomV6, prov.Province, "电信", "IPv6")
			provResults = append(provResults, result)
		}

		ipv6Results = append(ipv6Results, ProvinceResults{
			Province: prov.Province,
			Results:  provResults,
		})
	}

	// 显示结果
	displayResults(ipv4Results, ipv6Results)

	// 生成 Markdown
	generateMarkdown(ipv4Results, ipv6Results)
}

func testEndpoint(address, province, isp, ipVersion string) TestResult {
	fmt.Printf("  [%s-%s] 测试中...", isp, ipVersion)

	parts := strings.Split(address, ":")
	if len(parts) != 2 {
		fmt.Printf("\r  [%s-%s] 地址格式错误\n", isp, ipVersion)
		return TestResult{
			Province: province,
			ISP:      isp + "-" + ipVersion,
			LossRate: 100.0,
		}
	}

	host := parts[0]
	port := parts[1]
	addr := net.JoinHostPort(host, port)

	var latencies []int64
	successCount := 0
	failCount := 0

	for i := 0; i < *pingCount; i++ {
		start := time.Now()
		conn, err := net.DialTimeout("tcp", addr, time.Duration(*timeout)*time.Second)
		latency := time.Since(start).Milliseconds()

		if err == nil {
			conn.Close()
			latencies = append(latencies, latency)
			successCount++
		} else {
			failCount++
		}

		fmt.Printf("\r  [%s-%s] 测试中... %d/%d", isp, ipVersion, i+1, *pingCount)
		time.Sleep(100 * time.Millisecond)
	}

	// 清除进度行
	fmt.Print("\r\033[K")

	if len(latencies) == 0 {
		return TestResult{
			Province: province,
			ISP:      isp + "-" + ipVersion,
			LossRate: 100.0,
		}
	}

	// 计算统计数据
	var sum int64
	minLat := latencies[0]
	maxLat := latencies[0]

	for _, lat := range latencies {
		sum += lat
		if lat < minLat {
			minLat = lat
		}
		if lat > maxLat {
			maxLat = lat
		}
	}

	avgLat := float64(sum) / float64(len(latencies))
	lossRate := float64(failCount) / float64(*pingCount) * 100

	return TestResult{
		Province:   province,
		ISP:        isp + "-" + ipVersion,
		MinLatency: minLat,
		MaxLatency: maxLat,
		AvgLatency: avgLat,
		LossRate:   lossRate,
	}
}

func displayResults(ipv4Results, ipv6Results []ProvinceResults) {
	fmt.Printf("\n%s========================================\n", colorCyan)
	fmt.Printf("  测试结果\n")
	fmt.Printf("========================================\n%s\n", colorReset)

	// 显示 IPv4 结果
	fmt.Printf("%s=== IPv4 结果 ===%s\n\n", colorGreen, colorReset)
	for _, provResult := range ipv4Results {
		fmt.Printf("%s%s%s\n", colorYellow, provResult.Province, colorReset)
		fmt.Printf("%-12s %-10s %-10s %-10s %-10s\n", "运营商", "最快(ms)", "最慢(ms)", "平均(ms)", "丢包率(%)")
		fmt.Printf("%-12s %-10s %-10s %-10s %-10s\n", "----------", "--------", "--------", "--------", "---------")

		for _, result := range provResult.Results {
			if result.LossRate >= 100 {
				fmt.Printf("%-12s %-10s %-10s %-10s %-10.2f\n",
					result.ISP, "-", "-", "-", result.LossRate)
			} else {
				fmt.Printf("%-12s %-10d %-10d %-10.2f %-10.2f\n",
					result.ISP, result.MinLatency, result.MaxLatency, result.AvgLatency, result.LossRate)
			}
		}
		fmt.Println()
	}

	// 显示 IPv6 结果
	fmt.Printf("%s=== IPv6 结果 ===%s\n\n", colorGreen, colorReset)
	for _, provResult := range ipv6Results {
		fmt.Printf("%s%s%s\n", colorYellow, provResult.Province, colorReset)
		fmt.Printf("%-12s %-10s %-10s %-10s %-10s\n", "运营商", "最快(ms)", "最慢(ms)", "平均(ms)", "丢包率(%)")
		fmt.Printf("%-12s %-10s %-10s %-10s %-10s\n", "----------", "--------", "--------", "--------", "---------")

		for _, result := range provResult.Results {
			if result.LossRate >= 100 {
				fmt.Printf("%-12s %-10s %-10s %-10s %-10.2f\n",
					result.ISP, "-", "-", "-", result.LossRate)
			} else {
				fmt.Printf("%-12s %-10d %-10d %-10.2f %-10.2f\n",
					result.ISP, result.MinLatency, result.MaxLatency, result.AvgLatency, result.LossRate)
			}
		}
		fmt.Println()
	}
}

func generateMarkdown(ipv4Results, ipv6Results []ProvinceResults) {
	filename := *outputFile
	if filename == "" {
		filename = fmt.Sprintf("tcp-ping-results-%s.md", time.Now().Format("20060102-150405"))
	}

	var sb strings.Builder

	sb.WriteString("# TCP Ping 测试结果\n\n")
	sb.WriteString(fmt.Sprintf("**生成时间:** %s\n\n", time.Now().Format("2006-01-02 15:04:05")))

	// IPv4 结果
	sb.WriteString("## IPv4 测试结果\n\n")
	for _, provResult := range ipv4Results {
		sb.WriteString(fmt.Sprintf("\n| %s | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%%) |\n", provResult.Province))
		sb.WriteString("|--------|----------|----------|----------|-----------|\n")

		for _, result := range provResult.Results {
			if result.LossRate >= 100 {
				sb.WriteString(fmt.Sprintf("| %s | - | - | - | %.2f |\n",
					result.ISP, result.LossRate))
			} else {
				sb.WriteString(fmt.Sprintf("| %s | %d | %d | %.2f | %.2f |\n",
					result.ISP, result.MinLatency, result.MaxLatency, result.AvgLatency, result.LossRate))
			}
		}
	}

	// IPv6 结果
	sb.WriteString("\n## IPv6 测试结果\n\n")
	for _, provResult := range ipv6Results {
		sb.WriteString(fmt.Sprintf("\n| %s | 最快(ms) | 最慢(ms) | 平均(ms) | 丢包率(%%) |\n", provResult.Province))
		sb.WriteString("|--------|----------|----------|----------|-----------|\n")

		for _, result := range provResult.Results {
			if result.LossRate >= 100 {
				sb.WriteString(fmt.Sprintf("| %s | - | - | - | %.2f |\n",
					result.ISP, result.LossRate))
			} else {
				sb.WriteString(fmt.Sprintf("| %s | %d | %d | %.2f | %.2f |\n",
					result.ISP, result.MinLatency, result.MaxLatency, result.AvgLatency, result.LossRate))
			}
		}
	}

	sb.WriteString("---\n\n")
	sb.WriteString("**测试说明:**\n")
	sb.WriteString(fmt.Sprintf("- 每个节点测试 %d 次\n", *pingCount))
	sb.WriteString(fmt.Sprintf("- 超时时间: %d秒\n", *timeout))
	sb.WriteString(fmt.Sprintf("- 测试时间: %s\n", time.Now().Format("2006-01-02 15:04:05")))

	if err := ioutil.WriteFile(filename, []byte(sb.String()), 0644); err != nil {
		fmt.Printf("%s错误: 无法写入文件: %v%s\n", colorRed, err, colorReset)
		return
	}

	fmt.Printf("%s\n结果已保存: %s%s\n\n", colorGreen, filename, colorReset)
}
