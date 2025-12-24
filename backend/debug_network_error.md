# SnapAny Network Error 调试指南

## 🚨 问题：运行拦截器后出现 Network Error

这通常是因为拦截器意外地修改或破坏了原始请求。

---

## ✅ 解决方案：使用安全版本

我已经创建了一个**完全安全、只读的拦截器**：

```bash
cat backend/snapany_safe_interceptor.js
```

### 安全版本的特点：
- ✅ 只监听，不修改任何请求
- ✅ 使用 `JSON.parse(JSON.stringify())` 克隆数据
- ✅ 完全不干扰原始 fetch 调用
- ✅ 额外使用 PerformanceObserver 作为备用监控

---

## 🔄 重新开始的步骤

### 1. 刷新 SnapAny 页面
- 按 `Cmd+R` (Mac) 或 `F5` (Windows) 刷新页面
- 或者按 `Cmd+Shift+R` / `Ctrl+Shift+R` 强制刷新（清除缓存）

### 2. 重新打开控制台
- 按 `F12` 或 `Cmd+Option+I`

### 3. 复制安全版本的拦截器
```bash
# 在终端运行，查看脚本内容
cat backend/snapany_safe_interceptor.js
```

### 4. 粘贴到控制台
- 输入 `allow pasting`
- 粘贴整个脚本
- 按回车运行

### 5. 测试
- 在 SnapAny 输入 YouTube 链接
- 点击 "提取视频图片"
- 检查控制台输出

---

## 🔍 如果还是出现 Network Error

### 方法 A: 使用 Chrome Network 面板（最可靠）

1. **不要运行任何拦截脚本**
2. 打开开发者工具，切换到 **Network（网络）** 标签
3. 勾选 **Preserve log（保留日志）**
4. 在 SnapAny 输入 YouTube 链接并提取
5. 在 Network 列表中找到 `extract` 请求
6. 点击它，查看 **Headers（头部）** 标签
7. 找到 **Request Headers（请求头）**
8. 复制 `g-footer` 和 `g-timestamp` 的值

**这是最稳定的方法，不需要任何脚本！**

### 方法 B: 复制为 cURL

1. 在 Network 标签中，右键点击 `extract` 请求
2. 选择 **Copy** → **Copy as cURL (bash)**
3. 粘贴到文本编辑器中
4. 查找 `-H 'g-footer: xxx'` 和 `-H 'g-timestamp: xxx'`

示例输出：
```bash
curl 'https://api.snapany.com/v1/extract' \
  -H 'content-type: application/json' \
  -H 'g-footer: da55c7f33a6378ccb3b5c20534dd15d1' \
  -H 'g-timestamp: 1766495083604' \
  --data-raw '{"link":"https://www.youtube.com/watch?v=..."}'
```

### 方法 C: 复制为 Fetch

1. 右键点击 `extract` 请求
2. 选择 **Copy** → **Copy as fetch**
3. 粘贴到控制台（不要运行）
4. 查看代码中的 headers

---

## 📊 分析 Network Error 的原因

### 可能原因 1: CORS 错误
**症状**: 控制台显示 "has been blocked by CORS policy"

**解决方案**: 
- 拦截器不应该修改 origin 或 referer
- 使用安全版本的拦截器

### 可能原因 2: Headers 被破坏
**症状**: 请求发送了，但服务器返回 400 或 403

**解决方案**:
- 不要使用修改 headers 的拦截器
- 使用 Network 面板手动查看

### 可能原因 3: SnapAny 检测到异常
**症状**: 正常访问网站可以，运行脚本后不行

**解决方案**:
- 清除 Cookies 和缓存
- 使用隐身模式
- 换一个浏览器

### 可能原因 4: 频率限制
**症状**: 第一次可以，后续请求都失败

**解决方案**:
- 等待几分钟再试
- 这就是我们要解决的问题（破解 g-footer）

---

## 🎯 推荐流程（最稳定）

### 🥇 首选：直接使用 Chrome Network 面板

**不需要任何脚本，100% 可靠！**

1. **打开 SnapAny**: https://snapany.com/zh/youtube-1
2. **F12** → **Network** 标签
3. **筛选**: 在过滤框输入 `extract`
4. **测试**: 输入 YouTube 链接并提取
5. **点击** `extract` 请求
6. **查看** Request Headers
7. **复制** `g-footer` 和 `g-timestamp`

### 截图示例：

```
Request Headers:
  content-type: application/json
  g-footer: da55c7f33a6378ccb3b5c20534dd15d1    ← 复制这个
  g-timestamp: 1766495083604                    ← 复制这个
  origin: https://snapany.com
  referer: https://snapany.com/

Request Payload:
  {"link":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}  ← 复制这个
```

### 然后更新 Python 测试：

```python
# 编辑 backend/test_g_footer.py
TEST_LINK = "从 Payload 复制的链接"
TEST_TIMESTAMP = 从 Headers 复制的时间戳（数字）
ACTUAL_G_FOOTER = "从 Headers 复制的 g-footer"
```

运行测试：
```bash
cd backend
./venv/bin/python test_g_footer.py
```

---

## 🆘 如果所有方法都不行

### 最后的备选方案：使用浏览器扩展

有一些浏览器扩展可以帮助拦截和修改请求：

1. **Tampermonkey** (Chrome/Firefox)
   - 可以注入脚本到页面
   - 更稳定，不会被安全策略阻止

2. **EditThisCookie** (Chrome)
   - 查看和编辑 Cookies

3. **ModHeader** (Chrome)
   - 查看和修改 HTTP 头部

但是，**最简单的方法还是直接使用 Network 面板**！

---

## 📋 快速检查清单

在尝试运行拦截器之前：

- [ ] 已刷新 SnapAny 页面
- [ ] 控制台没有其他错误
- [ ] 网络连接正常
- [ ] 没有其他扩展干扰
- [ ] 使用的是最新版本的 Chrome 或 Firefox

如果全部确认，使用**安全版本的拦截器**：
```bash
cat backend/snapany_safe_interceptor.js
```

---

## 🎯 我的建议

**跳过拦截器，直接使用 Network 面板！**

这样：
- ✅ 100% 不会出错
- ✅ 不需要输入 "allow pasting"
- ✅ 不需要担心语法错误
- ✅ 可以看到完整的请求和响应
- ✅ 可以复制为 cURL 或 Fetch 代码

只需要：
1. F12 → Network
2. 输入链接并提取
3. 点击 `extract` 请求
4. 复制 Headers 中的值

**就这么简单！** 🎉

