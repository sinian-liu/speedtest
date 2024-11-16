#!/bin/bash

# 定义 DNS 服务器列表（地区和对应的 IP 地址）
declare -A dns_servers=(
    ["广东省广州市（电信）"]="61.144.56.100"
    ["福建省厦门市（电信）"]="202.101.103.55"
    ["江苏省南京市（电信）"]="218.2.135.1"
    ["浙江省杭州市（电信）"]="202.101.172.35"
    ["广东省河源市（联通）"]="210.21.196.5"
    ["山东省青岛市（联通）"]="202.102.134.68"
    ["山东省济宁市（联通）"]="202.102.154.3"
    ["广东省广州市（铁通）"]="61.235.70.98"
    ["云南省（铁通）"]="211.98.72.7"
    ["辽宁省朝阳市（铁通）"]="61.232.206.102"
    ["河南省安阳市（铁通）"]="211.98.192.3"
    ["湖南省永州市（长城宽带）"]="219.72.225.254"
)

# 测试文件 URL（用于下载速度测试）
test_file_url="http://speedtest.ftp.otenet.gr/files/test10Mb.db"

# 获取终端宽度
term_width=$(tput cols)

# 设置列宽（动态自适应）
col1_width=$((term_width / 3))  # 地区列宽
col2_width=$((term_width / 4))  # 下载速度列宽
col3_width=$((term_width / 4))  # 上传速度列宽
col4_width=$((term_width / 4))  # 延迟列宽
col5_width=$((term_width / 4))  # 抖动列宽

# 输出表头（全居中对齐）
echo -e "\033[33m$(printf "%*s" $(( (col1_width + ${#'地区'}) / 2 ))地区)\033[0m"
echo -e "\033[36m$(printf "%*s" $(( (col2_width + ${#'下载速度'}) / 2 ))下载速度)\033[0m"
echo -e "\033[32m$(printf "%*s" $(( (col3_width + ${#'上传速度'}) / 2 ))上传速度)\033[0m"
echo -e "\033[38;5;214m$(printf "%*s" $(( (col4_width + ${#'延迟'}) / 2 ))延迟)\033[0m"
echo -e "\033[31m$(printf "%*s" $(( (col5_width + ${#'抖动'}) / 2 ))抖动)\033[0m"
echo "---------------------------------------------------------------------------------------------"

# 格式化速度为 KB/s 或 MB/s
function format_speed() {
    local speed_kb="$1"
    if (( $(echo "$speed_kb > 1000" | bc -l) )); then
        echo "$(awk "BEGIN {printf \"%.2f MB/s\", $speed_kb / 1024}")"
    else
        echo "$(awk "BEGIN {printf \"%.2f KB/s\", $speed_kb}")"
    fi
}

# 定义测试函数
function test_dns() {
    local region="$1"
    local dns="$2"

    # 测试延迟和抖动
    ping_result=$(ping -c 4 "$dns" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        latency="失败"
        jitter="失败"
    else
        latency=$(echo "$ping_result" | awk -F'/' 'END {print $5 " ms"}')
        jitter=$(echo "$ping_result" | awk -F'/' 'END {print $6 " ms"}')
    fi

    # 测试下载速度
    download_speed=$(curl -o /dev/null -s -w '%{speed_download}' "$test_file_url")
    if [[ $? -ne 0 ]]; then
        download_speed="失败"
    else
        download_speed=$(format_speed "$(awk "BEGIN {print $download_speed / 1024}")")
    fi

    # 模拟上传速度（发送小数据到测试接口）
    upload_test_url="https://httpbin.org/post"
    start_time=$(date +%s%N)
    curl -X POST -d "test upload" -s -o /dev/null "$upload_test_url"
    end_time=$(date +%s%N)
    elapsed=$(( (end_time - start_time) / 1000000 )) # 转换为毫秒
    if [[ $? -ne 0 ]]; then
        upload_speed="失败"
    else
        upload_speed=$(format_speed "$(awk "BEGIN {print 11 / ($elapsed / 1000)}")") # 数据长度为 11 字节
    fi

    # 输出每一行数据，居中对齐
    printf "%*s%-*s%*s%-*s%*s%-*s\n" $(( (col1_width + ${#region}) / 2 )) "" "$col1_width" "$region" \
        $(( (col2_width + ${#download_speed}) / 2 )) "" "$col2_width" "$download_speed" \
        $(( (col3_width + ${#upload_speed}) / 2 )) "" "$col3_width" "$upload_speed" \
        $(( (col4_width + ${#latency}) / 2 )) "" "$col4_width" "$latency" \
        $(( (col5_width + ${#jitter}) / 2 )) "" "$col5_width" "$jitter"
}

# 循环测试每个 DNS
for region in "${!dns_servers[@]}"; do
    test_dns "$region" "${dns_servers[$region]}"
done

# 测试完成后
test_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "---------------------------------------------------------------------------------------------"
echo "测试时间: $test_time"

# 显示系统时间
system_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "系统时间: $system_time"
