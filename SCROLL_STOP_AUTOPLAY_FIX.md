# 🚫 YouTube 滑动停止后自动播放拦截方案

## 📋 问题描述

在 YouTube 首页浏览视频时,当用户**滑动停止**的瞬间,YouTube 会自动触发视频预览播放,这会:
- ⚠️ 干扰用户浏览体验
- ⚠️ 消耗不必要的流量
- ⚠️ 让用户误以为要跳转到播放页面

## ✅ 解决方案

采用**多层防护机制**,从根本上阻止视频自动播放:

### 1️⃣ 重写 HTMLMediaElement 原型(核心)

通过重写 `HTMLMediaElement.prototype`,从根本上禁用所有 video 元素的播放能力:

```javascript
(function patchVideo() {
    if (window.lsrVideoPatched) return;
    window.lsrVideoPatched = true;
    const proto = HTMLMediaElement.prototype;
    
    // 禁用 play() 方法
    const blockPlay = function() {
        try { this.pause(); } catch(e) {}
        return Promise.reject(new DOMException('blocked', 'NotAllowedError'));
    };
    proto.play = blockPlay;
    
    // 禁用 src setter
    const srcDesc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
    if (srcDesc && srcDesc.set) {
        Object.defineProperty(HTMLMediaElement.prototype, 'src', {
            get: srcDesc.get,
            set: function(_) {
                try { 
                    this.pause(); 
                    this.removeAttribute('src'); 
                    this.load(); 
                } catch(e) {}
            },
            configurable: true
        });
    }
    
    // 禁用 load() 方法
    const origLoad = proto.load;
    proto.load = function() {
        try { this.pause(); } catch(e) {}
        return;
    };
})();
```

**效果**: 任何 video 元素调用 `play()` 都会被立即暂停并返回 rejected Promise。

---

### 2️⃣ CSS 样式隐藏(辅助)

隐藏所有视频预览元素:

```css
ytd-thumbnail video,
ytd-moving-thumbnail-renderer video,
ytd-video-preview video,
ytd-player video,
.html5-video-player video {
    display: none !important;
    pointer-events: none !important;
}

ytd-thumbnail img { 
    opacity: 1 !important; 
}

ytd-player, #player, .html5-video-player { 
    pointer-events: none !important; 
}
```

---

### 3️⃣ 事件监听 + 定时清理(兜底)

监听滚动/触摸事件,在滑动停止时立即清理视频:

```javascript
function scrubVideos() {
    var videos = document.querySelectorAll('video');
    videos.forEach(function(video) {
        try { video.pause(); } catch(e) {}
        video.removeAttribute('src');
        video.load();
    });
}

// 立即执行
scrubVideos();

// 监听滚动/触摸事件,防止滑动停止后自动播放
['scroll', 'touchend', 'wheel', 'visibilitychange'].forEach(function(evt) {
    document.addEventListener(evt, scrubVideos, true);
});

// 监听 DOM 变化,处理动态加载的视频
var observer = new MutationObserver(function(mutations) {
    let foundVideo = false;
    for (const m of mutations) {
        if (m.addedNodes && m.addedNodes.length) {
            foundVideo = true; 
            break;
        }
    }
    if (foundVideo) scrubVideos();
});
observer.observe(document.documentElement || document.body, { 
    childList: true, 
    subtree: true 
});

// 定时兜底(每 500ms)
setInterval(scrubVideos, 500);
```

---

## 🔧 实现位置

### 文件: `YouTubeWebView.swift`

#### 位置 1: `YouTubeWebView.Coordinator.webView(_:didFinish:)` (第 82-175 行)

在简单的 WebView 中注入脚本。

#### 位置 2: `YouTubeWebViewWithControls.Coordinator.webView(_:didFinish:)` (第 502-598 行)

在带控制的 WebView 中注入完整的拦截脚本,包括:
- ✅ `patchVideo()` 函数(重写原型)
- ✅ CSS 样式隐藏
- ✅ 滚动/触摸事件监听
- ✅ DOM 变化监听
- ✅ 定时清理

---

## 📊 防护层级

```
用户滑动页面
    ↓
滑动停止
    ↓
YouTube 尝试播放视频
    ↓
┌─────────────────────────────────┐
│ 第 1 层: HTMLMediaElement.play() │ ← 被重写,立即 pause()
│         返回 rejected Promise     │
└─────────────────────────────────┘
    ↓ (如果绕过)
┌─────────────────────────────────┐
│ 第 2 层: CSS display: none       │ ← 视频元素不可见
│         pointer-events: none     │
└─────────────────────────────────┘
    ↓ (如果绕过)
┌─────────────────────────────────┐
│ 第 3 层: touchend 事件监听       │ ← 滑动停止时清理
│         scrubVideos()            │
└─────────────────────────────────┘
    ↓ (如果绕过)
┌─────────────────────────────────┐
│ 第 4 层: MutationObserver        │ ← 监听 DOM 变化
│         发现新视频立即清理         │
└─────────────────────────────────┘
    ↓ (如果绕过)
┌─────────────────────────────────┐
│ 第 5 层: setInterval(500ms)      │ ← 定时兜底清理
└─────────────────────────────────┘
    ↓
✅ 视频无法播放
```

---

## 🎯 关键改进

### 之前的问题

```javascript
// 仅依赖定时清理,可能在滑动停止的瞬间被 YouTube 抢先播放
setInterval(scrubVideos, 500);
```

**问题**: YouTube 在滑动停止后立即调用 `video.play()`,而定时器可能还没触发。

### 现在的解决方案

```javascript
// 1. 从根本上禁用 play() 方法
proto.play = function() {
    this.pause();
    return Promise.reject(new DOMException('blocked', 'NotAllowedError'));
};

// 2. 监听 touchend 事件,滑动停止时立即清理
document.addEventListener('touchend', scrubVideos, true);

// 3. 定时器作为兜底
setInterval(scrubVideos, 500);
```

**效果**: 
- ✅ YouTube 调用 `video.play()` 会立即被拦截
- ✅ 滑动停止的瞬间就会清理视频
- ✅ 定时器确保没有遗漏

---

## ✅ 测试清单

验证功能是否正常工作:

- [x] 滑动页面,视频不会自动播放
- [x] 滑动停止后,视频依然不会播放
- [x] 鼠标悬停在缩略图上,没有预览
- [x] 静态缩略图正常显示
- [x] 点击视频标题/图片,正确跳转到应用内播放器
- [x] 新加载的视频也不会自动播放
- [x] 控制台无 video.play() 相关错误

---

## 🎉 总结

通过**多层防护机制**:
1. **重写原型** - 从根本上禁用播放
2. **CSS 隐藏** - 视觉上完全隐藏
3. **事件监听** - 滑动停止时立即清理
4. **DOM 监听** - 处理动态加载
5. **定时兜底** - 确保没有遗漏

**只有在点击视频标题/图片进入详情页时,才使用自己的播放器播放!** 🎯

---

## 🔗 相关文档

- **DISABLE_HOVER_PLAY_GUIDE.md** - 禁用悬停播放的基础指南
- **URL_INTERCEPT_FLOW.md** - URL 拦截和跳转流程
- **YOUTUBE_WEBVIEW_GUIDE.md** - WebView 完整说明

**滑动体验已优化!** ✨
