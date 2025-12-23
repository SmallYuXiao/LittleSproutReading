# 调试指南 - URL 拦截问题排查

## 当前实现的拦截策略

我们使用了**三层拦截机制**来确保 YouTube 视频链接被正确拦截：

### 1️⃣ WKUserScript（早期注入）
- **时机**: 页面加载开始时（`atDocumentStart`）
- **方法**: JavaScript 事件监听器（捕获阶段）
- **优势**: 最早执行，在 YouTube 的 JS 之前

### 2️⃣ 页面加载完成后注入
- **时机**: `didFinish` 回调
- **方法**: 动态注入 JavaScript
- **优势**: 确保在所有元素加载后也有拦截器

### 3️⃣ WKNavigationDelegate
- **时机**: 导航请求发生时
- **方法**: `decidePolicyFor navigationAction`
- **优势**: 原生拦截，最可靠

---

## 如何查看调试信息

### 第 1 步：打开 Safari Web Inspector

1. 在 iPhone/iPad **设置** → **Safari** → **高级** → 开启 **"网页检查器"**

2. 在 Mac 上打开 **Safari** → **开发** 菜单
   - 如果没有"开发"菜单：Safari → 偏好设置 → 高级 → 勾选"在菜单栏中显示开发菜单"

3. 连接设备到 Mac，运行应用

4. Safari → **开发** → 选择你的设备 → 选择 **WebView** 页面

### 第 2 步：查看 Console 日志

在 Safari Web Inspector 的 **Console** 标签中，你应该看到：

```
🔧 [Early] YouTube 拦截脚本（早期注入）
🎯 设置视频链接拦截器...
✅ [Early] 拦截器激活
```

当点击视频时：
```
🔗 [Interceptor] 点击: https://www.youtube.com/watch?v=...
🎬 [Interceptor] 视频链接！阻止并导航
```

### 第 3 步：查看 Xcode Console

在 Xcode 的 **Console** 中查看原生日志：

```
🌐 [WebView] 导航事件:
   URL: https://www.youtube.com/watch?v=...
   类型: 0 (0=链接点击, -1=其他)

🔍 [URLParser] 解析 URL: https://www.youtube.com/watch?v=...
   Host: www.youtube.com
   Path: /watch
   格式: youtube.com/watch
   结果: dQw4w9WgXcQ

============================================================
🎬 [WebView] 检测到 YouTube 视频！
📹 视频 ID: dQw4w9WgXcQ
🔗 原始 URL: https://www.youtube.com/watch?v=...
🚀 拦截导航，跳转到应用内播放器...
============================================================

🎯 [ViewModel] loadVideo() 被调用
   ✅ currentVideo 已设置

🖥️ [ContentView] 显示播放器页面 - videoID: dQw4w9WgXcQ
```

---

## 问题排查步骤

### 问题 1: 点击视频没有任何反应

**检查清单**:
- [ ] Safari Web Inspector 中是否有 "🔧 拦截脚本已注入" 日志？
- [ ] 点击时是否有 "🔗 点击链接" 日志？
- [ ] Xcode Console 中是否有 "🌐 导航事件" 日志？

**可能原因**:
1. **YouTube 使用了 SPA 导航** - 没有触发真正的页面跳转
2. **JavaScript 被禁用** - 检查 WebView 配置
3. **点击被其他事件处理器拦截** - YouTube 的 JS 先处理了

**解决方案**:
- 尝试点击不同的视频元素（缩略图、标题、频道名）
- 查看 Safari Console 中的所有点击事件

---

### 问题 2: 有 "点击链接" 日志，但没有 "视频链接" 日志

**检查**:
- 查看 Console 中打印的 URL 是什么格式
- 是否匹配我们支持的格式？

**支持的 URL 格式**:
```
✅ https://www.youtube.com/watch?v=VIDEO_ID
✅ https://youtu.be/VIDEO_ID
✅ https://m.youtube.com/watch?v=VIDEO_ID
✅ https://www.youtube.com/shorts/VIDEO_ID
✅ https://www.youtube.com/embed/VIDEO_ID
```

**不支持的格式**:
```
❌ https://www.youtube.com/c/ChannelName
❌ https://www.youtube.com/user/UserName
❌ https://www.youtube.com/playlist?list=...
❌ /watch?v=... (相对路径)
```

**解决方案**:
在 `YouTubeURLParser.swift` 中添加新的 URL 格式支持

---

### 问题 3: 有 "视频链接" 和 "阻止并导航" 日志，但页面没有切换

**检查**:
- Xcode Console 中是否有 "🌐 导航事件" 日志？
- 是否有 "🎯 loadVideo() 被调用" 日志？
- 是否有 "🖥️ 显示播放器页面" 日志？

**可能原因**:
1. `window.location.href` 导航被阻止
2. `currentVideo` 没有正确设置
3. SwiftUI 状态更新问题

**解决方案 1: 强制导航**
```javascript
// 在 JavaScript 中添加：
window.webkit.messageHandlers.videoSelected.postMessage(url);
```

**解决方案 2: 使用 evaluateJavaScript 获取 URL**
```swift
webView.evaluateJavaScript("document.URL") { result, error in
    // 手动检测 URL 变化
}
```

---

### 问题 4: WebView 显示空白或加载失败

**检查**:
- 网络连接是否正常
- YouTube 是否可以访问
- Console 中是否有错误信息

**可能原因**:
- 地区限制
- 网络代理问题
- YouTube 检测到自动化访问

**解决方案**:
- 尝试在 Safari 中打开相同的 URL
- 检查设备的网络设置

---

## 手动测试步骤

### 测试 1: 验证 URL 解析器

在 Xcode 中运行以下测试：

```swift
let testURLs = [
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "https://youtu.be/dQw4w9WgXcQ",
    "https://m.youtube.com/watch?v=dQw4w9WgXcQ",
    "https://www.youtube.com/shorts/abc123",
]

for url in testURLs {
    if let videoID = YouTubeURLParser.extractVideoID(from: url) {
        print("✅ \(url) → \(videoID)")
    } else {
        print("❌ \(url) → 无法解析")
    }
}
```

### 测试 2: 验证 decidePolicyFor 被调用

在 `decidePolicyFor` 方法的第一行添加：
```swift
print("⚡️ decidePolicyFor 被调用！URL: \(url?.absoluteString ?? "nil")")
```

### 测试 3: 验证页面切换逻辑

在 `ContentView` 中添加：
```swift
.onReceive(viewModel.$currentVideo) { video in
    if let video = video {
        print("🔔 currentVideo 改变: \(video.youtubeVideoID)")
    } else {
        print("🔔 currentVideo 为 nil")
    }
}
```

---

## 备用方案

如果所有方法都失败了，可以尝试以下备用方案：

### 方案 A: 使用自定义 URL Scheme

1. 注入 JS 修改所有视频链接：
```javascript
let links = document.querySelectorAll('a[href*="/watch"]');
links.forEach(link => {
    link.href = 'myapp://youtube/' + extractVideoID(link.href);
});
```

2. 在应用中注册 URL Scheme 处理

### 方案 B: 定时检查 URL 变化

```swift
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    webView.evaluateJavaScript("window.location.href") { result, _ in
        if let url = result as? String,
           let videoID = YouTubeURLParser.extractVideoID(from: url) {
            // 检测到视频页面
        }
    }
}
```

### 方案 C: 使用 WKURLSchemeHandler

自定义 URL Scheme 来完全控制资源加载。

---

## 关键代码位置

### 拦截相关
- `YouTubeWebView.swift:290-310` - decidePolicyFor 方法
- `YouTubeWebView.swift:180-230` - UserScript 注入
- `YouTubeWebView.swift:290-350` - didFinish 中的动态注入

### URL 解析
- `YouTubeURLParser.swift:17-90` - extractVideoID 方法

### 页面切换
- `ContentView.swift:24` - 条件判断 `if let video = viewModel.currentVideo`
- `VideoPlayerViewModel.swift:50-67` - loadVideo 方法

---

## 联系与反馈

如果以上方法都无法解决问题，请收集以下信息：

1. Xcode Console 的完整日志
2. Safari Web Inspector Console 的日志
3. 点击的具体是什么元素（截图）
4. YouTube 页面的 URL

---

**创建日期**: 2025-12-23
**最后更新**: 2025-12-23

