import os
import time
import subprocess
import statistics
from urllib.request import urlopen

# 设置不同地区的DNS（按电信、联通、铁通、广电等运营商分类，删除备选DNS）
dns_servers = {
    "广东省广州市（电信）": '61.144.56.100',
    "福建省厦门市（电信）": '202.101.103.55',
    "江苏省南京市（电信）": '218.2.135.1',
    "浙江省杭州市（电信）": '202.101.172.35',
    "广东省河源市（联通）": '210.21.196.5',
    "山东省青岛市（联通）": '202.102.134.68',
    "山东省济宁市（联通）": '202.102.154.3',
    "广东省广州市（铁通）": '61.235.70.98',
    "云南省（铁通）": '211.98.72.7',
    "辽宁省朝阳市（铁通）": '61.232.206.102',
    "河南省安阳市（铁通）": '211.98.192.3',
    "湖南省永州市（长城宽带）": '219.72.225.254'
}

# 下载测试文件URL（选择一个合适的文件用于下载速度测试）
test_file_url = "http://speedtest.ftp.otenet.gr/files/test10Mb.db"

# 上传测试的URL (您可以选择一个有效的文件上传 URL)
upload_test_url = "https://httpbin.org/post"  # 这是一个可以测试上传的 API

# 延迟测试函数
def ping(host):
    cmd = f"ping -c 4 {host}"
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        # 提取延迟信息
        lines = result.stdout.splitlines()
        times = [float(line.split('time=')[1].split(' ')[0]) for line in lines if 'time=' in line]
        jitter = statistics.stdev(times) if len(times) > 1 else 0
        avg_latency = sum(times) / len(times) if times else None
        return avg_latency, jitter
    else:
        return None, None

# 下载速度测试函数
def download_speed(url):
    start_time = time.time()
    try:
        with urlopen(url) as response:
            data = response.read()
        end_time = time.time()
        download_time = end_time - start_time
        speed = len(data) / download_time / 1024  # KB/s
        return speed
    except Exception as e:
        return None

# 上传速度测试函数
def upload_speed(url):
    # 使用curl命令上传一个小文件来模拟上传速度
    start_time = time.time()
    file_data = 'test upload'  # 只上传一小段数据
    try:
        cmd = f"curl -X POST -d '{file_data}' {url} -s -o /dev/null"
        subprocess.run(cmd, shell=True, check=True)
        end_time = time.time()
        upload_time = end_time - start_time
        # 上传的数据大小为`file_data`的长度
        speed = len(file_data) / upload_time / 1024  # KB/s
        return speed
    except Exception as e:
        return None

# 测试每个DNS服务器
def test_dns(dns_data):
    results = []
    for region, dns in dns_data.items():
        print(f"正在测试 {region} DNS服务器...")

        # 延迟和抖动测试
        avg_latency, jitter = ping(dns)
        if avg_latency is None:
            latency_str = "Ping失败"
            jitter_str = "N/A"
        else:
            latency_str = f"{avg_latency:.2f} ms"
            jitter_str = f"{jitter:.2f} ms"

        # 下载速度测试
        download_speed_value = download_speed(test_file_url)
        if download_speed_value is None:
            download_str = "下载失败"
        else:
            download_str = f"{download_speed_value:.2f} KB/s"

        # 上传速度测试
        upload_speed_value = upload_speed(upload_test_url)
        if upload_speed_value is None:
            upload_str = "上传失败"
        else:
            upload_str = f"{upload_speed_value:.2f} KB/s"

        results.append({
            '地区': region,
            '上传速度': upload_str,
            '下载速度': download_str,
            '延迟': latency_str,
            '抖动': jitter_str
        })
    
    return results

# 输出结果
def print_results(results):
    print(f"{'地区':<30}{'上传速度':<20}{'下载速度':<20}{'延迟':<20}{'抖动':<20}")
    print("-" * 120)
    for result in results:
        print(f"{result['地区']:<30}{result['上传速度']:<20}{result['下载速度']:<20}{result['延迟']:<20}{result['抖动']:<20}")

# 测试DNS
print("正在测试电信、联通、铁通等各地区的DNS服务器：")
dns_results = test_dns(dns_servers)
print_results(dns_results)
