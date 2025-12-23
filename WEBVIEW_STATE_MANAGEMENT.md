# WebView 状态管理说明

## 问题背景

在实现 YouTube WebView 浏览器时，遇到了以下挑战：

1. **返回时页面刷新** - WebView 被重新创建，导致重新加载
2. **滚动位置丢失** - 用户浏览的位置无法保存
3. **第二次点击失效** - WebView 重用后拦截功能失效

---

## 解决方案

### 1. WebView 实例重用

使用静态变量保持 WebView 实例在视图重建时不被销毁：

```swift
private static var sharedWebView: WKWebView?
private static var hasLoadedInitialPage = false
```

**优势**：
- ✅ 避免重复创建，节省内存
- ✅ 保持页面状态，不需要重新加载
- ✅ 用户体验更流畅

### 2. navigationDelegate 状态管理

**关键点**：每次 WebView 重用时，必须重新设置 `navigationDelegate`

```swift
func makeUIView(context: Context) -> WKWebView {
    if let existingWebView = Self.sharedWebView {
        // 重新设置 delegate，确保拦截功能正常
        existingWebView.navigationDelegate = context.coordinator
        return existingWebView
    }
    // ... 创建新 WebView
}
```

**在 updateUIView 中双重保险**：

```swift
func updateUIView(_ webView: WKWebView, context: Context) {
    // 确保 navigationDelegate 始终正确
    if webView.navigationDelegate !== context.coordinator {
        webView.navigationDelegate = context.coordinator
    }
}
```

### 3. 滚动位置保存与恢复

**保存时机**：`onDisappear`
```swift
webView.evaluateJavaScript("window.scrollY") { result, error in
    if let scrollY = result as? CGFloat {
        savedScrollPosition = CGPoint(x: 0, y: scrollY)
    }
}
```

**恢复时机**：`updateUIView`（延迟 0.3 秒）
```swift
webView.evaluateJavaScript("window.scrollTo(0, \(scrollY))")
```

**防止重复恢复**：
```swift
var hasRestoredPosition = false  // Coordinator 中的标志
```

### 4. 状态重置

在 `onAppear` 中重置标志，允许下次返回时再次恢复：

```swift
.onAppear {
    if let delegate = webView?.navigationDelegate as? Coordinator {
        delegate.hasRestoredPosition = false
    }
}
```

---

## 完整生命周期

### 第一次启动

```
App 启动
  ↓
makeUIView() 被调用
  ↓
sharedWebView == nil
  ↓
创建新的 WKWebView
保存到 sharedWebView
设置 navigationDelegate = coordinator
注入 UserScript
  ↓
加载 YouTube 首页
hasLoadedInitialPage = true
  ↓
用户浏览和滚动
```

### 点击视频

```
用户点击视频
  ↓
JavaScript 拦截器捕获点击
  ↓
window.location.href = 视频 URL
  ↓
decidePolicyFor 被调用
  ↓
提取 videoID
  ↓
decisionHandler(.cancel) - 取消导航
  ↓
调用 viewModel.loadVideo()
  ↓
onDisappear 触发
  ↓
保存滚动位置 (savedScrollPosition)
  ↓
显示播放器页面
```

### 从播放器返回

```
用户点击返回
  ↓
viewModel.currentVideo = nil
  ↓
ContentView 切换到 WebView
  ↓
onAppear 触发
重置 hasRestoredPosition = false
  ↓
makeUIView() 被调用
  ↓
sharedWebView != nil (已存在)
  ↓
重新设置 navigationDelegate = coordinator
  ↓
返回现有 WebView 实例
跳过重复加载
  ↓
updateUIView() 被调用
  ↓
检查 savedScrollPosition > 0
  ↓
延迟 0.3 秒
  ↓
执行 window.scrollTo(0, savedScrollPosition.y)
  ↓
滚动位置恢复 ✅
hasRestoredPosition = true
  ↓
用户看到之前的位置
可以继续点击视频
```

### 第二次点击视频

```
用户再次点击视频
  ↓
JavaScript 拦截器捕获
  ↓
decidePolicyFor 被调用
（因为 navigationDelegate 已正确设置）
  ↓
检测到视频链接
  ↓
拦截成功 ✅
  ↓
跳转到播放器
  ↓
... 循环往复
```

---

## 关键代码位置

### WebView 实例管理
- **文件**: `YouTubeWebView.swift`
- **位置**: 
  - 第 245-248 行：静态变量定义
  - 第 254-260 行：重用逻辑
  - 第 308-312 行：创建并保存实例

### navigationDelegate 设置
- **文件**: `YouTubeWebView.swift`
- **位置**:
  - 第 257-259 行：makeUIView 中重新设置
  - 第 322-325 行：updateUIView 中检查

### 滚动位置管理
- **文件**: `YouTubeWebView.swift`
- **位置**:
  - 第 148-152 行：onDisappear 保存
  - 第 327-344 行：updateUIView 恢复
  - 第 154-162 行：saveScrollPosition 方法

### URL 拦截
- **文件**: `YouTubeWebView.swift`
- **位置**:
  - 第 347-387 行：decidePolicyFor 实现
  - 第 251-302 行：UserScript 注入

---

## 调试日志说明

### 正常流程的日志

**首次启动**：
```
🆕 [WebView] 创建新的 WebView 实例
🌐 [WebView] WebView 初始化完成
🌐 [WebView] 首次加载首页: ...
```

**点击视频**：
```
🔗 [Interceptor] 点击: https://www.youtube.com/watch?v=...
🎬 [Interceptor] 视频链接！阻止并导航
⚡️ [Coordinator] decidePolicyFor 被调用
🌐 [WebView] 导航事件:
   类型: 0 (链接点击)
🎬 [WebView] 检测到 YouTube 视频！
🖥️ [WebView] WebView 视图消失，保存滚动位置
💾 [WebView] 保存滚动位置: Y = 1500.0
```

**返回 WebView**：
```
🖥️ [WebView] WebView 视图出现
   🔄 已重置 hasRestoredPosition
♻️ [WebView] 重用现有 WebView 实例
   ✅ navigationDelegate 已重新设置
♻️ [WebView] 跳过重复加载，保持当前页面
📍 [WebView] 在 updateUIView 中恢复滚动位置: Y = 1500.0
✅ [WebView] 滚动位置已恢复
```

**第二次点击视频**：
```
🔗 [Interceptor] 点击: https://www.youtube.com/watch?v=...
⚡️ [Coordinator] decidePolicyFor 被调用
🎬 [WebView] 检测到 YouTube 视频！
（正常拦截）✅
```

### 异常情况的日志

**如果点击不起作用**：
```
🔗 [Interceptor] 点击: ...
（没有 "decidePolicyFor 被调用" 日志）
❌ navigationDelegate 未正确设置
```

**解决方法**：检查 makeUIView 和 updateUIView 中的 delegate 设置

---

## 常见问题

### Q1: 第二次点击视频没反应

**原因**：navigationDelegate 没有被重新设置

**解决**：
1. 在 makeUIView 重用时重新设置
2. 在 updateUIView 中检查并更新
3. 查看日志中是否有 "decidePolicyFor 被调用"

### Q2: 滚动位置没有恢复

**原因**：
- 恢复时机太早，页面还没渲染
- hasRestoredPosition 没有重置

**解决**：
1. 在 updateUIView 中延迟恢复
2. 在 onAppear 中重置标志

### Q3: WebView 还是重新加载了

**原因**：
- sharedWebView 被清空
- hasLoadedInitialPage 被重置

**检查**：
1. 确认静态变量正确声明
2. 查看日志是否有 "创建新的 WebView 实例"

---

## 性能优化

### 内存使用

- **单例 WebView**：常驻内存 ~50-100MB
- **优势**：避免重复创建和加载，节省总体内存
- **劣势**：应用运行期间一直占用

### 网络流量

- **首次加载**：~2-5MB（YouTube 页面）
- **之后返回**：0MB（完全复用）
- **节省**：每次返回节省 2-5MB 流量

### 用户体验

- **首次进入**：1-2 秒加载
- **返回时**：< 0.1 秒（即时显示）
- **滚动恢复**：~0.3 秒（平滑动画）

---

## 替代方案

如果静态变量方案不适合，可以考虑：

### 方案 A: EnvironmentObject 管理

```swift
class WebViewManager: ObservableObject {
    var webView: WKWebView?
    var scrollPosition: CGPoint = .zero
}
```

### 方案 B: 使用 UIKit Container

直接在 UIKit 层管理 WebView，不通过 SwiftUI

### 方案 C: 完全重新加载

每次都创建新的 WebView，使用 URL 历史恢复位置

---

**创建日期**: 2025-12-23  
**最后更新**: 2025-12-23  
**版本**: 1.0

