# SnapAny API g-footer 逆向工程指南

## 目标
找出 SnapAny API 请求头中 `g-footer` 和 `g-timestamp` 的生成逻辑。

---

## 📋 准备工作

### 必需工具
- **Chrome 或 Firefox 浏览器**（推荐 Chrome）
- **浏览器开发者工具**（F12）
- **文本编辑器**（用于分析代码）

---

## 🔍 第一步：捕获完整请求

### 1.1 打开 SnapAny 网站
访问：https://snapany.com/zh/youtube-1

### 1.2 打开开发者工具
- 按 `F12` 或 `Cmd+Option+I` (Mac)
- 切换到 **Network（网络）** 标签
- 勾选 **Preserve log（保留日志）**
- 勾选 **Disable cache（禁用缓存）**

### 1.3 清空并准备捕获
1. 点击 🚫 图标清空当前请求列表
2. 在 Filter（筛选器）中输入 `extract` 来过滤请求

### 1.4 触发请求
1. 在网站输入框中粘贴一个 YouTube 链接，例如：
   ```
   https://www.youtube.com/watch?v=dQw4w9WgXcQ
   ```
2. 点击 **"提取视频图片"** 按钮
3. 观察 Network 面板中出现的 `extract` 请求

### 1.5 记录请求详情
点击 `extract` 请求，查看：

**Request Headers（请求头）：**
```
content-type: application/json
g-footer: da55c7f33a6378ccb3b5c20534dd15d1  ← 关键！
g-timestamp: 1766495083604                   ← 关键！
origin: https://snapany.com
referer: https://snapany.com/
user-agent: Mozilla/5.0 ...
```

**Request Payload（请求体）：**
```json
{
  "link": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

---

## 🕵️ 第二步：定位 JavaScript 代码

### 2.1 切换到 Sources（源代码）标签

### 2.2 查找主 JavaScript 文件
在左侧文件树中，展开 `snapany.com` 域：
- 查找名称类似的文件：
  - `app.js`
  - `main.js`
  - `chunk-*.js`
  - `bundle.js`
  - `index-*.js`

### 2.3 搜索关键字
在 Sources 面板中按 `Cmd+Shift+F` (Mac) 或 `Ctrl+Shift+F` (Windows)，打开全局搜索。

**搜索以下关键字：**
1. `g-footer` - 直接搜索头部名称
2. `g-timestamp` - 时间戳字段
3. `v1/extract` - API 端点
4. `setRequestHeader` - 设置请求头的代码
5. `timestamp` - 可能的变量名
6. `sign` 或 `signature` - 签名相关
7. `md5` 或 `sha` - 常见的哈希算法

### 2.4 常见代码模式
寻找类似以下的代码片段：

**模式 1：直接设置头部**
```javascript
headers['g-footer'] = calculateFooter(data);
headers['g-timestamp'] = Date.now();
```

**模式 2：使用 axios 或 fetch**
```javascript
axios.post('/v1/extract', data, {
  headers: {
    'g-footer': generateFooter(),
    'g-timestamp': timestamp
  }
});
```

**模式 3：请求拦截器**
```javascript
axios.interceptors.request.use(config => {
  config.headers['g-footer'] = someFunction();
  config.headers['g-timestamp'] = Date.now();
  return config;
});
```

---

## 🧩 第三步：分析 g-footer 生成逻辑

### 3.1 常见的签名算法模式

#### 模式 A: MD5/SHA 哈希
```javascript
// 可能的实现
const footer = md5(timestamp + secretKey + url);
const footer = sha256(JSON.stringify(payload) + timestamp);
```

#### 模式 B: 基于时间戳的签名
```javascript
const timestamp = Date.now();
const footer = md5(`${timestamp}:${apiKey}:${link}`);
```

#### 模式 C: 多参数组合
```javascript
const footer = crypto.createHash('md5')
  .update(timestamp + method + path + body + secret)
  .digest('hex');
```

### 3.2 使用断点调试

1. **找到可疑函数后，点击行号设置断点**
2. **刷新页面或重新触发请求**
3. **当代码执行到断点时暂停**
4. **查看 Call Stack（调用堆栈）**
5. **查看 Scope（作用域）中的变量值**
6. **逐步执行（Step Over / Step Into）**

### 3.3 控制台测试
如果找到了生成函数（例如 `generateFooter`），可以在 Console 中测试：

```javascript
// 测试函数
console.log(generateFooter());

// 查看函数源码
console.log(generateFooter.toString());

// 测试不同输入
generateFooter({ link: "https://youtube.com/test" });
```

---

## 📊 第四步：逆向分析技巧

### 4.1 处理代码混淆

如果代码被混淆（变量名像 `a`, `b`, `c`），使用以下技巧：

**美化代码：**
- 在 Sources 面板，点击代码底部的 `{}` 按钮
- 或使用在线工具：https://beautifier.io/

**使用 Chrome 的 Local Overrides：**
1. 在 Sources > Overrides 中启用本地覆盖
2. 保存美化后的代码到本地
3. 添加 `console.log()` 语句来追踪变量

### 4.2 动态分析

**在可疑函数中插入日志：**
```javascript
// 原始代码
function someFunction(param) {
  const result = calculateSomething(param);
  return result;
}

// 添加调试
function someFunction(param) {
  console.log('输入参数:', param);
  const result = calculateSomething(param);
  console.log('计算结果:', result);
  return result;
}
```

### 4.3 网络请求堆栈追踪

在 Network 面板中：
1. 点击 `extract` 请求
2. 切换到 **Initiator（发起者）** 标签
3. 查看调用堆栈，找到发起请求的代码位置
4. 点击堆栈中的链接，直接跳转到源码

---

## 🎯 第五步：验证和实现

### 5.1 多次测试
使用不同的：
- YouTube 链接
- 时间戳
- 浏览器环境

观察 `g-footer` 的变化规律。

### 5.2 找出规律
记录多次请求的数据：

| 时间戳 | YouTube 链接 | g-footer 值 | 是否成功 |
|--------|--------------|-------------|----------|
| 1766495083604 | youtube.com/watch?v=abc | da55c7f33a6378ccb3b5c20534dd15d1 | ✅ |
| 1766495123456 | youtube.com/watch?v=xyz | e8f6a9b44c7389dde4b6c31645dd26f2 | ✅ |

分析：
- `g-footer` 是否每次都不同？
- 是否与 `g-timestamp` 相关？
- 是否与 `link` 参数相关？
- 长度是否固定？（32 字符 = MD5，40 = SHA1，64 = SHA256）

### 5.3 Python 实现

一旦找到算法，在 `youtube_iiilab.py` 中实现：

```python
import hashlib
import time

def generate_g_footer(timestamp: int, link: str) -> str:
    """
    生成 g-footer 签名
    
    TODO: 根据逆向分析的结果实现此函数
    目前的实现是猜测，需要通过实际分析来验证
    """
    # 示例实现（需要替换为实际算法）
    data = f"{timestamp}:{link}:SOME_SECRET_KEY"
    return hashlib.md5(data.encode()).hexdigest()

def make_request(link: str):
    timestamp = int(time.time() * 1000)  # 毫秒时间戳
    footer = generate_g_footer(timestamp, link)
    
    headers = {
        "Content-Type": "application/json",
        "g-footer": footer,
        "g-timestamp": str(timestamp),
        "origin": "https://snapany.com",
        "referer": "https://snapany.com/"
    }
    
    # ... 发送请求
```

---

## 🚨 可能的挑战

### 挑战 1: 需要密钥
如果 `g-footer` 的计算需要一个服务器密钥（secret key），这个密钥可能：
- 硬编码在 JavaScript 中（可以找到）
- 动态从服务器获取（难以绕过）
- 加密存储（需要进一步逆向）

### 挑战 2: 动态算法
如果算法会定期更换，我们的实现会失效。

### 挑战 3: 环境检测
SnapAny 可能检测：
- User-Agent
- Referer
- 请求来源 IP
- 浏览器指纹

### 挑战 4: 代码混淆严重
大型网站通常使用：
- Webpack 打包
- UglifyJS 压缩
- 字符串加密
- 控制流平坦化

---

## 📝 记录你的发现

创建一个文档记录：

```markdown
## 发现记录

### 日期：2025-12-23

### JavaScript 文件位置
- 主文件：https://snapany.com/assets/index-abc123.js
- 行数：第 4567 行

### g-footer 生成函数
```javascript
function generateFooter(link, timestamp) {
  // 复制实际代码
}
```

### 算法描述
- 使用 MD5 哈希
- 输入：timestamp + link + 常量 "YOUR_SECRET"
- 输出：32 位十六进制字符串

### 测试结果
- ✅ 本地测试通过
- ✅ 实际请求成功
- ⚠️ 每 100 次请求会触发一次频率限制
```

---

## ⚖️ 法律和道德提醒

### ⚠️ 重要注意事项

1. **服务条款**：逆向工程可能违反 SnapAny 的服务条款
2. **版权法**：某些国家/地区禁止绕过技术保护措施
3. **仅用于学习**：此指南仅供教育和研究目的
4. **商业使用**：如需商业使用，请联系 SnapAny 官方获取授权
5. **备选方案**：考虑使用官方 API 或其他合法的视频服务

### 建议
- 保持合理的请求频率
- 不要用于大规模爬取
- 考虑联系 SnapAny 官方申请合作
- 探索其他合法的 YouTube 视频服务（如 YouTube Data API v3）

---

## 🔄 下一步

1. **按照上述步骤分析 SnapAny 网站**
2. **记录你的发现**
3. **如果成功找到算法，更新 `youtube_iiilab.py`**
4. **测试新的实现是否能减少频率限制错误**

---

## 📞 需要帮助？

如果你在分析过程中遇到困难：
1. 截图你看到的代码片段
2. 记录你尝试过的步骤
3. 描述遇到的具体问题

祝你逆向工程顺利！🎉

