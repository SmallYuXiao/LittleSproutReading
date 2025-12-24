# SnapAny g-footer 逆向工程完整指南

## 📦 工具包概览

我已经为你创建了一套完整的逆向工程工具：

### 1. **Python 测试工具** (`backend/test_g_footer.py`)
- 自动测试 10+ 种常见签名算法
- 支持交互式模式
- 提供浏览器拦截脚本

### 2. **浏览器拦截器** (`backend/snapany_interceptor.html`)
- 可视化操作界面
- 一键复制拦截脚本
- 详细的使用说明

### 3. **逆向指南** (`SNAPANY_REVERSE_ENGINEERING_GUIDE.md`)
- 完整的逆向工程步骤
- 调试技巧和最佳实践
- 法律和道德提醒

---

## 🚀 快速开始

### 方案 A：浏览器拦截（推荐）⭐

**适合：零编程基础，想要快速结果的用户**

1. **打开拦截器页面**
   ```bash
   open backend/snapany_interceptor.html
   ```
   或直接在浏览器中打开这个 HTML 文件。

2. **复制拦截脚本**
   - 页面上有一个大的代码框，点击 "📋 复制脚本" 按钮

3. **访问 SnapAny 网站**
   - 打开 https://snapany.com/zh/youtube-1
   - 按 `F12` 打开开发者工具
   - 切换到 **Console（控制台）** 标签

4. **运行拦截脚本**
   - 在控制台粘贴刚才复制的脚本
   - 按回车运行

5. **测试并捕获**
   - 在 SnapAny 页面输入任意 YouTube 链接
   - 点击 "提取视频图片"
   - 观察控制台输出的详细信息

6. **获取关键数据**
   控制台会显示：
   ```javascript
   ✅ 成功捕获签名数据！
   g-footer: da55c7f33a6378ccb3b5c20534dd15d1
   g-timestamp: 1766495083604
   Body: {"link":"https://www.youtube.com/watch?v=..."}
   
   📋 复制以下数据用于 Python 测试：
   TEST_LINK = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
   TEST_TIMESTAMP = 1766495083604
   ACTUAL_G_FOOTER = "da55c7f33a6378ccb3b5c20534dd15d1"
   ```

7. **使用 Python 测试**
   - 复制控制台输出的 Python 代码
   - 更新 `backend/test_g_footer.py` 文件顶部的常量
   - 运行：
     ```bash
     cd backend
     ./venv/bin/python test_g_footer.py
     ```

---

### 方案 B：直接使用 Python 测试

**适合：已经抓包过的用户**

1. **更新测试数据**
   
   编辑 `backend/test_g_footer.py`，修改顶部常量：
   ```python
   TEST_LINK = "你的 YouTube 链接"
   TEST_TIMESTAMP = 你的时间戳（数字）
   ACTUAL_G_FOOTER = "你抓到的 g-footer 值"
   ```

2. **运行测试**
   ```bash
   cd backend
   ./venv/bin/python test_g_footer.py
   ```

3. **查看结果**
   - ✅ 如果找到匹配，脚本会显示正确的算法
   - ❌ 如果没找到，使用方案 A 的浏览器拦截方法

---

### 方案 C：交互式测试

**适合：需要测试多个数据点的用户**

```bash
cd backend
./venv/bin/python test_g_footer.py --interactive
```

然后按提示输入：
- YouTube 链接
- g-timestamp
- 实际的 g-footer 值

---

## 📊 预期结果

### 如果算法被破解 ✅

脚本会显示：
```
🎉 找到匹配的算法！
   ✅ MD5(timestamp + link + 'secret_key')
      值: da55c7f33a6378ccb3b5c20534dd15d1
```

然后你可以：
1. 记录下算法和密钥
2. 实现到 `backend/youtube_iiilab.py` 中
3. 测试是否能减少 API 频率限制错误

### 如果算法未破解 ❌

可能的原因：
1. **动态密钥**：密钥是从服务器动态获取的
2. **复杂加密**：使用了自定义加密算法
3. **环境依赖**：依赖 Cookie、Session、IP 等
4. **代码混淆严重**：签名函数被深度混淆

---

## 🔍 深度分析技巧

### 1. 使用浏览器断点

在控制台运行拦截脚本后，如果看到 `console.trace()` 输出了调用堆栈：

```
at Function.setRequestHeader (<anonymous>:42:21)
at generateRequestHeaders (index-abc123.js:4567:15)
at makeAPICall (index-abc123.js:8901:10)
```

**点击堆栈中的链接**（如 `index-abc123.js:4567`），会跳转到源码位置。

### 2. 搜索关键字

在 Sources 标签中按 `Cmd+Shift+F`（Mac）或 `Ctrl+Shift+F`（Windows），搜索：
- `g-footer`
- `g-timestamp`
- `md5`（如果 footer 是 32 个字符）
- `crypto`
- `sign`

### 3. 设置条件断点

在 Sources 中找到疑似代码后：
1. 点击行号设置断点
2. 右键断点 → Edit breakpoint
3. 添加条件，如：`header === 'g-footer'`
4. 重新触发请求，代码会在此处暂停

### 4. 查看 Network Initiator

在 Network 标签中：
1. 找到 `extract` 请求
2. 点击后切换到 **Initiator** 标签
3. 查看 **Call Stack**
4. 点击链接跳转到发起代码

---

## 🛠️ 实现到项目中

一旦找到算法，编辑 `backend/youtube_iiilab.py`：

```python
import hashlib
import time

class IIILabYouTubeService:
    def __init__(self):
        self.api_url = "https://api.snapany.com/v1/extract"
        self.secret_key = "YOUR_FOUND_SECRET"  # 从逆向中获取
        # ...
    
    def _generate_g_footer(self, timestamp: int, link: str) -> str:
        """
        生成 g-footer 签名
        
        根据逆向分析的结果实现
        """
        # 示例：假设算法是 MD5(timestamp + link + secret)
        data = f"{timestamp}{link}{self.secret_key}"
        return hashlib.md5(data.encode()).hexdigest()
    
    def extract_video_info(self, youtube_url: str) -> Dict:
        """提取 YouTube 视频信息"""
        self._wait_for_rate_limit()
        
        # 生成时间戳和签名
        timestamp = int(time.time() * 1000)
        g_footer = self._generate_g_footer(timestamp, youtube_url)
        
        headers = {
            "Content-Type": "application/json",
            "g-footer": g_footer,
            "g-timestamp": str(timestamp),
            "origin": "https://snapany.com",
            "referer": "https://snapany.com/",
            "User-Agent": "Mozilla/5.0 ..."
        }
        
        payload = {"link": youtube_url}
        
        # 发送请求...
```

---

## 📈 测试新实现

编辑 `backend/test_translation.py` 或创建新文件：

```python
from youtube_iiilab import IIILabYouTubeService

service = IIILabYouTubeService()

# 测试几个视频
test_urls = [
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "https://www.youtube.com/watch?v=jNQXAC9IVRw"
]

for url in test_urls:
    try:
        info = service.extract_video_info(url)
        print(f"✅ {url}")
        print(f"   标题: {info.get('title')}")
        print(f"   时长: {info.get('duration')}")
    except Exception as e:
        print(f"❌ {url}: {e}")
```

运行：
```bash
cd backend
./venv/bin/python test_translation.py
```

---

## ⚠️ 可能的挑战

### 挑战 1: 找不到密钥

**症状**: 所有算法都不匹配

**解决方案**:
1. 密钥可能是硬编码在 JS 中的常量，搜索：
   ```javascript
   const SECRET = "..."
   const API_KEY = "..."
   const SIGN_KEY = "..."
   ```

2. 或者从远程加载，查找类似的请求：
   ```javascript
   fetch('/api/config').then(r => r.json())
   ```

3. 或者基于浏览器指纹生成，检查是否使用了：
   - `navigator.userAgent`
   - `screen.width/height`
   - `navigator.language`
   - Canvas fingerprinting

### 挑战 2: 算法使用了加密库

**症状**: 找到了生成函数，但它调用了混淆的加密库

**解决方案**:
1. 在控制台拦截加密库的输入输出：
   ```javascript
   const originalMd5 = window.md5;
   window.md5 = function(input) {
       console.log('MD5 输入:', input);
       const result = originalMd5(input);
       console.log('MD5 输出:', result);
       return result;
   };
   ```

2. 或者使用 Chrome DevTools 的 "Overrides" 功能修改 JS 文件

### 挑战 3: 代码被严重混淆

**症状**: 所有变量都是 `a`, `b`, `c`，代码难以阅读

**解决方案**:
1. 使用在线美化工具：https://beautifier.io/
2. 使用 de4js：https://lelinhtinh.github.io/de4js/
3. 在 Chrome Sources 中点击 `{}` 按钮美化代码
4. 重命名变量以提高可读性（右键变量 → Rename）

### 挑战 4: 频率限制依然存在

**症状**: 即使添加了正确的 g-footer，还是被限制

**可能原因**:
- IP 被限制（使用不同 IP 测试）
- Cookie/Session 验证（添加 Cookie 头）
- User-Agent 检测（使用真实浏览器的 UA）
- Referer 检查（确保设置了 `referer: https://snapany.com/`）

---

## 🎯 成功指标

你会知道逆向成功，当：

✅ Python 测试脚本显示 "🎉 找到匹配的算法！"

✅ 使用新算法的请求能成功返回视频信息

✅ 频率限制错误明显减少（从每次都出错到偶尔出错）

✅ 可以稳定地获取 YouTube 视频的播放地址和字幕

---

## 📞 需要帮助？

如果在逆向过程中遇到困难：

1. **检查输出**
   - 确保控制台没有错误
   - 确认拦截脚本已成功运行
   - 验证 g-footer 和 g-timestamp 已被捕获

2. **收集信息**
   - 截图控制台输出
   - 记录调用堆栈
   - 保存 Network 请求的 HAR 文件

3. **尝试不同方法**
   - 使用不同浏览器（Chrome、Firefox、Edge）
   - 清除浏览器缓存和 Cookie
   - 使用隐身模式

4. **考虑备选方案**
   - 联系 SnapAny 官方申请 API 访问
   - 使用 YouTube Data API v3（官方、合法）
   - 探索其他第三方服务

---

## ⚖️ 法律声明

**重要提醒**：

1. 本指南仅供**教育和学习目的**
2. 逆向工程可能违反服务条款
3. 商业使用前请获得官方授权
4. 遵守当地法律法规
5. 尊重知识产权

**建议的合法途径**：
- 📧 联系 SnapAny: hi@iiilab.com
- 🌐 访问官网: https://snapany.com/
- 💼 申请商业授权和 API 密钥

---

## 📚 相关文档

- **SNAPANY_REVERSE_ENGINEERING_GUIDE.md** - 详细的逆向步骤
- **API_RATE_LIMIT_FIX.md** - API 频率限制问题及解决方案
- **IIILAB_API_EXPLANATION.md** - iiilab API 的完整说明
- **backend/test_g_footer.py** - Python 测试工具
- **backend/snapany_interceptor.html** - 浏览器拦截器

---

## 🎉 祝你逆向成功！

记住：逆向工程是一个学习过程，即使没有完全破解算法，你也会学到很多关于 Web 安全、加密和 API 设计的知识。

**Good luck! 🚀**

