#!/usr/bin/env python3
"""
SnapAny g-footer 算法测试工具

用法：
1. 先运行这个脚本，它会尝试不同的算法
2. 在浏览器中访问 SnapAny，使用开发者工具记录实际的 g-footer 值
3. 对比测试结果，找出正确的算法
"""

import hashlib
import time
import json
import hmac
from typing import Dict, List, Tuple

# 测试数据
TEST_LINK = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
TEST_TIMESTAMP = 1766495083604  # 从你的抓包中获取的实际时间戳
ACTUAL_G_FOOTER = "da55c7f33a6378ccb3b5c20534dd15d1"  # 从你的抓包中获取的实际值


def md5_hash(text: str) -> str:
    """计算 MD5 哈希"""
    return hashlib.md5(text.encode()).hexdigest()


def sha1_hash(text: str) -> str:
    """计算 SHA1 哈希"""
    return hashlib.sha1(text.encode()).hexdigest()


def sha256_hash(text: str) -> str:
    """计算 SHA256 哈希"""
    return hashlib.sha256(text.encode()).hexdigest()


def hmac_md5(text: str, key: str) -> str:
    """计算 HMAC-MD5"""
    return hmac.new(key.encode(), text.encode(), hashlib.md5).hexdigest()


# 算法测试套件
def test_algorithms() -> List[Tuple[str, str, bool]]:
    """
    测试各种可能的 g-footer 生成算法
    返回: [(算法名称, 生成的值, 是否匹配), ...]
    """
    results = []
    
    # 常见的密钥候选
    possible_secrets = [
        "",  # 无密钥
        "snapany",
        "iiilab",
        "youtube",
        "extract",
        "api-key",
        "secret",
        "YOUR_SECRET_KEY",
    ]
    
    
    # 算法 1: 纯时间戳
    result = md5_hash(str(TEST_TIMESTAMP))
    match = result == ACTUAL_G_FOOTER
    results.append(("MD5(timestamp)", result, match))
    
    # 算法 2: 时间戳 + 链接
    result = md5_hash(f"{TEST_TIMESTAMP}{TEST_LINK}")
    match = result == ACTUAL_G_FOOTER
    results.append(("MD5(timestamp + link)", result, match))
    
    # 算法 3: 链接 + 时间戳
    result = md5_hash(f"{TEST_LINK}{TEST_TIMESTAMP}")
    match = result == ACTUAL_G_FOOTER
    results.append(("MD5(link + timestamp)", result, match))
    
    # 算法 4: JSON payload
    payload = json.dumps({"link": TEST_LINK}, separators=(',', ':'))
    result = md5_hash(f"{TEST_TIMESTAMP}{payload}")
    match = result == ACTUAL_G_FOOTER
    results.append(("MD5(timestamp + JSON)", result, match))
    
    # 算法 5: 带密钥的组合
    for secret in possible_secrets:
        result = md5_hash(f"{TEST_TIMESTAMP}{TEST_LINK}{secret}")
        match = result == ACTUAL_G_FOOTER
        results.append((f"MD5(timestamp + link + '{secret}')", result, match))
        if match:
    
    # 算法 6: 反向组合 (secret + timestamp + link)
    for secret in possible_secrets:
        result = md5_hash(f"{secret}{TEST_TIMESTAMP}{TEST_LINK}")
        match = result == ACTUAL_G_FOOTER
        results.append((f"MD5('{secret}' + timestamp + link)", result, match))
        if match:
    
    # 算法 7: 使用冒号分隔
    for secret in possible_secrets:
        result = md5_hash(f"{TEST_TIMESTAMP}:{TEST_LINK}:{secret}")
        match = result == ACTUAL_G_FOOTER
        results.append((f"MD5(timestamp:link:'{secret}')", result, match))
        if match:
    
    # 算法 8: HMAC-MD5
    for secret in possible_secrets:
        if secret:  # HMAC 需要密钥
            result = hmac_md5(f"{TEST_TIMESTAMP}{TEST_LINK}", secret)
            match = result == ACTUAL_G_FOOTER
            results.append((f"HMAC-MD5(timestamp+link, key='{secret}')", result, match))
            if match:
    
    # 算法 9: 只用链接的一部分
    video_id = TEST_LINK.split("v=")[-1] if "v=" in TEST_LINK else TEST_LINK
    result = md5_hash(f"{TEST_TIMESTAMP}{video_id}")
    match = result == ACTUAL_G_FOOTER
    results.append(("MD5(timestamp + video_id)", result, match))
    
    # 算法 10: 使用 SHA256
    result = sha256_hash(f"{TEST_TIMESTAMP}{TEST_LINK}")[:32]  # 截取前32位
    match = result == ACTUAL_G_FOOTER
    results.append(("SHA256(timestamp + link)[:32]", result, match))
    
    
    # 检查是否有匹配
    matches = [r for r in results if r[2]]
    if matches:
        for algo, value, _ in matches:
    else:
    
    
    return results


def generate_browser_script():
    """生成用于浏览器的拦截脚本"""
    script = """
// ========================================
// SnapAny g-footer 拦截脚本
// ========================================
// 使用方法：
// 1. 在 SnapAny 网站上打开浏览器控制台（F12）
// 2. 粘贴并运行此脚本
// 3. 点击"提取视频图片"按钮
// 4. 查看控制台输出的 g-footer 生成过程

(function() {
    console.log('🔍 SnapAny g-footer 拦截脚本已启动');
    
    // 拦截所有 fetch 请求
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        const [url, options] = args;
        
        if (url.includes('api.snapany.com') || url.includes('extract')) {
            console.log('=' .repeat(80));
            console.log('🎯 拦截到 SnapAny API 请求！');
            console.log('URL:', url);
            console.log('Method:', options?.method);
            console.log('Headers:', options?.headers);
            console.log('Body:', options?.body);
            console.log('=' .repeat(80));
            
            // 尝试解析 g-footer 的来源
            if (options?.headers) {
                const gFooter = options.headers['g-footer'];
                const gTimestamp = options.headers['g-timestamp'];
                if (gFooter) {
                    console.log('✅ g-footer:', gFooter);
                    console.log('✅ g-timestamp:', gTimestamp);
                    console.log('📝 请将这些值记录下来用于逆向分析');
                }
            }
        }
        
        return originalFetch.apply(this, args);
    };
    
    // 拦截 XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    const originalSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
    const xhrHeaders = new WeakMap();
    
    XMLHttpRequest.prototype.open = function(method, url, ...rest) {
        if (url.includes('api.snapany.com') || url.includes('extract')) {
            this._intercepted = true;
            this._url = url;
            this._method = method;
            xhrHeaders.set(this, {});
        }
        return originalOpen.apply(this, [method, url, ...rest]);
    };
    
    XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
        if (this._intercepted) {
            const headers = xhrHeaders.get(this) || {};
            headers[header] = value;
            xhrHeaders.set(this, headers);
            
            if (header === 'g-footer' || header === 'g-timestamp') {
                console.log('=' .repeat(80));
                console.log('🎯 拦截到 setRequestHeader！');
                console.log('Header:', header);
                console.log('Value:', value);
                console.log('调用堆栈：');
                console.trace();
                console.log('=' .repeat(80));
            }
        }
        return originalSetRequestHeader.apply(this, arguments);
    };
    
    // 尝试搜索 g-footer 相关的全局变量或函数
    console.log('🔎 搜索可能相关的全局函数...');
    for (let key in window) {
        if (key.toLowerCase().includes('footer') || 
            key.toLowerCase().includes('sign') || 
            key.toLowerCase().includes('hash') ||
            key.toLowerCase().includes('md5')) {
            console.log('   可疑函数:', key, '=', typeof window[key]);
        }
    }
    
    console.log('✅ 拦截脚本准备完成！现在可以测试了。');
})();
"""
    return script


def print_browser_instructions():
    """打印浏览器端操作说明"""


def interactive_test():
    """交互式测试模式"""
    global TEST_LINK, TEST_TIMESTAMP, ACTUAL_G_FOOTER
    
    
    try:
        link = input("YouTube 链接 (留空使用默认): ").strip() or TEST_LINK
        timestamp_str = input("g-timestamp (留空使用默认): ").strip()
        timestamp = int(timestamp_str) if timestamp_str else TEST_TIMESTAMP
        g_footer = input("实际的 g-footer 值 (留空使用默认): ").strip() or ACTUAL_G_FOOTER
        
        
        # 使用输入的值进行测试
        TEST_LINK = link
        TEST_TIMESTAMP = timestamp
        ACTUAL_G_FOOTER = g_footer
        
        test_algorithms()
        
    except KeyboardInterrupt:
    except Exception as e:


if __name__ == "__main__":
    import sys
    
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    SnapAny g-footer 算法逆向工具                             ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
    """)
    
    if len(sys.argv) > 1 and sys.argv[1] == "--browser":
        # 只打印浏览器脚本
        print_browser_instructions()
    elif len(sys.argv) > 1 and sys.argv[1] == "--interactive":
        # 交互式模式
        interactive_test()
    else:
        # 默认：运行所有测试
        test_algorithms()
        print_browser_instructions()

