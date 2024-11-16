# 定义颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m' # 黄色
NC='\033[0m' # No Color

# 延迟测试函数，执行三次并取平均值
ping_test() {
    local host="$1"
    local total=0
    local count=3
    local jitter_total=0
    local jitter_count=0
    for i in $(seq 1 $count); do
        local output
        output=$(ping -c 4 "$host" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local times
            times=$(echo "$output" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
            for time in $times; do
                total=$(echo "$total + $time" | bc)
                jitter_total=$(echo "$jitter_total + $time" | bc)
                ((jitter_count++))
            done
        else
            echo "失败 N/A"
            return
        fi
    done
    local avg=$(echo "scale=2; $total / ($count * $jitter_count)" | bc)
    local jitter_avg=$(echo "scale=2; $jitter_total / $jitter_count" | bc)
    echo "$avg $jitter_avg"
}

# 下载速度测试函数，执行三次并取平均值
download_speed_test() {
    local total_speed=0
    local count=3
    for i in $(seq 1 $count); do
        local start_time end_time size speed
        start_time=$(date +%s.%N)
        size=$(curl -s --max-time 15 -o /dev/null -w "%{size_download}" "$test_file_url")
        end_time=$(date +%s.%N)
        if [ $? -eq 0 ]; then
            speed=$(echo "scale=2; $size / 1024 / ($end_time - $start_time)" | bc)
            total_speed=$(echo "$total_speed + $speed" | bc)
        else
            echo "失败"
            return
        fi
    done
    local avg_speed=$(echo "scale=2; $total_speed / $count" | bc)
    if (( $(echo "$avg_speed >= 1024" | bc -l) )); then
        echo "$(echo "scale=2; $avg_speed / 1024" | bc) MB/s"
    else
        echo "$avg_speed KB/s"
    fi
}

# 上传速度测试函数，执行三次并取平均值
upload_speed_test() {
    local total_speed=0
    local count=3
    for i in $(seq 1 $count); do
        local start_time end_time size speed
        start_time=$(date +%s.%N)
        size=$(curl -s --max-time 15 -o /dev/null -w "%{size_upload}" -X POST -d "test_data=test" "https://httpbin.org/post")
        end_time=$(date +%s.%N)
        if [ $? -eq 0 ]; then
            speed=$(echo "scale=2; $size / 1024 / ($end_time - $start_time)" | bc)
            total_speed=$(echo "$total_speed + $speed" | bc)
        else
            echo "失败"
            return
        fi
    done
    local avg_speed=$(echo "scale=2; $total_speed / $count" | bc)
    if (( $(echo "$avg_speed >= 1024" | bc -l) )); then
        echo "$(echo "scale=2; $avg_speed / 1024" | bc) MB/s"
    else
        echo "$avg_speed KB/s"
    fi
}

# 输出结果函数，进行三次测试并显示平均结果
print_results() {
    printf "%-30s%-15s%-15s%-15s%-15s\n" "地区" "上传速度" "下载速度" "延迟" "抖动"
    echo "-------------------------------------------------------------------------------------------"
    for region in "${!dns_servers[@]}"; do
        dns=${dns_servers[$region]}
        latency_jitter=$(ping_test "$dns")
        latency=$(echo "$latency_jitter" | awk '{print $1}')
        jitter=$(echo "$latency_jitter" | awk '{print $2}')
        download_speed=$(download_speed_test)
        upload_speed=$(upload_speed_test)
        printf "%-30s%-15s%-15s%-15s%-15s\n" "${YELLOW}$region${NC}" \
               "${GREEN}$upload_speed${NC}" \
               "${GREEN}$download_speed${NC}" \
               "${BLUE}$latency${NC}" \
               "${RED}$jitter${NC}"
    done
}

# 执行测试
print_results
