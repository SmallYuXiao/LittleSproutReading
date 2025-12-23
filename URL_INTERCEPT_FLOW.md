# URL 拦截和视频播放流程

## 概述

当用户在 WebView 中浏览 YouTube 并点击视频时，应用会自动拦截 URL，调用后端 Render API 获取播放地址，然后在应用内播放。

---

## 完整流程图

```
用户操作
  ↓
1. 在 WebView 中浏览 Ariannita la Gringa 频道
  ↓
2. 点击任意视频（例如："How to use In, On, At in English"）
  ↓
3. WebView 拦截 YouTube 视频 URL
  ↓
4. 提取视频 ID (例如: dQw4w9WgXcQ)
  ↓
5. 调用后端 Render API
   📡 GET https://littlesproutreading.onrender.com/api/youtube-info/{videoID}
  ↓
6. 后端调用 iiiLab 服务解析视频
  ↓
7. 返回视频信息：
   - 视频标题
   - 多种清晰度的播放地址
   - 字幕信息（英文、中文）
  ↓
8. 前端选择最佳播放格式
  ↓
9. AVPlayer 加载视频 URL 并播放
  ↓
10. 同时加载和显示双语字幕
  ↓
用户开始学习 🎉
```

---

## 详细代码流程

### 1. WebView URL 拦截

**文件**: `YouTubeWebView.swift`

```swift
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, 
             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    
    // 获取导航 URL
    guard let url = navigationAction.request.url else {
        decisionHandler(.allow)
        return
    }
    
    let urlString = url.absoluteString
    
    // 检测 YouTube 视频链接
    if let videoID = YouTubeURLParser.extractVideoID(from: urlString) {
        print("🎬 检测到视频 ID: \(videoID)")
        
        // ⚠️ 关键：取消原始导航，拦截 URL
        decisionHandler(.cancel)
        
        // 跳转到应用内播放器
        let video = Video(youtubeVideoID: videoID, title: "Loading...")
        viewModel.loadVideo(video, originalURL: urlString)
        return
    }
    
    // 允许其他导航（浏览页面）
    decisionHandler(.allow)
}
```

**支持的 URL 格式**:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://m.youtube.com/watch?v=VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`

---

### 2. 加载视频

**文件**: `VideoPlayerViewModel.swift`

```swift
func loadVideo(_ video: Video, originalURL: String = "") {
    currentVideo = video
    originalInputURL = originalURL
    
    // 加载 YouTube 字幕和视频
    loadYouTubeSubtitles(video)
}
```

---

### 3. 调用后端 API

**文件**: `YouTubeSubtitleService.swift`

```swift
func fetchVideoInfoWithSubtitles(videoID: String) async throws -> YouTubeVideoInfoResponse {
    let apiURL = "https://littlesproutreading.onrender.com/api/youtube-info/\(videoID)"
    
    print("📡 请求: \(apiURL)")
    
    let (data, response) = try await URLSession.shared.data(from: URL(string: apiURL)!)
    
    let result = try JSONDecoder().decode(YouTubeVideoInfoResponse.self, from: data)
    
    return result
}
```

**API 响应示例**:
```json
{
  "success": true,
  "title": "How to use In, On, At in English",
  "thumbnail": "https://...",
  "duration": 600,
  "formats": [
    {
      "quality": "720p",
      "format": "mp4",
      "video_url": "https://rr1---sn-...",
      "has_audio": true,
      "separate": false
    },
    ...
  ],
  "subtitles": [
    {
      "language": "en",
      "language_name": "English",
      "url": "https://...",
      "format": "srt"
    },
    {
      "language": "zh-Hans",
      "language_name": "Chinese (Simplified)",
      "url": "https://...",
      "format": "srt"
    }
  ]
}
```

---

### 4. 选择最佳视频格式

**文件**: `VideoPlayerViewModel.swift`

```swift
private func selectBestFormat(from formats: [VideoFormat]) -> VideoFormat? {
    // 优先选择音视频合并的格式（AVPlayer 需要）
    let notSeparateFormats = formats.filter { !$0.separate }
    
    if !notSeparateFormats.isEmpty {
        // 选择质量最高的
        return notSeparateFormats.sorted { $0.quality_value > $1.quality_value }.first
    }
    
    return nil
}
```

**选择规则**:
1. 优先选择音视频合并的格式（`separate = false`）
2. 在合并格式中，选择质量最高的（`quality_value` 最大）
3. 如果都是分离的，返回 `nil`（AVPlayer 无法直接播放）

---

### 5. 加载视频 URL

**文件**: `VideoPlayerViewModel.swift`

```swift
func loadVideoFromURL(_ urlString: String) {
    guard let url = URL(string: urlString) else { return }
    
    print("🎬 加载视频: \(urlString.prefix(80))...")
    
    let playerItem = AVPlayerItem(url: url)
    player = AVPlayer(playerItem: playerItem)
    
    // 监听视频就绪状态
    playerItem.publisher(for: \.status)
        .sink { status in
            if status == .readyToPlay {
                print("✅ 视频就绪，开始播放")
                self.player?.play()
            }
        }
        .store(in: &cancellables)
}
```

---

### 6. 加载双语字幕

**流程**:
1. 查找英文字幕（优先原生字幕）
2. 查找中文字幕（原生 > 后端翻译 > Smart URL 翻译）
3. 下载字幕内容（SRT 格式）
4. 合并双语字幕（按时间戳匹配）
5. 显示在界面上

**代码片段**:
```swift
// 查找英文字幕
let englishSubtitle = subtitles.first(where: {
    $0.language.contains("en")
})

// 查找中文字幕（三级回退）
var chineseSubtitle = subtitles.first(where: {
    $0.language.contains("zh")
})

if chineseSubtitle == nil {
    // 尝试后端翻译
    chineseSubs = try await fetchSubtitles(videoID: videoID, language: "zh")
}

// 合并字幕
let mergedSubtitles = mergeSubtitles(english: englishSubs, chinese: chineseSubs)
```

---

## 后端 API 实现

**文件**: `backend/app.py`

```python
@app.route('/api/youtube-info/<path:video_id>', methods=['GET'])
def get_youtube_info(video_id):
    """
    使用 iiilab 服务获取 YouTube 视频信息
    """
    try:
        logger.info(f"Fetching YouTube info for: {video_id}")
        
        # 构建 YouTube URL
        youtube_url = build_youtube_url(video_id)
        
        # 调用 iiilab 服务
        result = iiilab_service.extract_video_info(youtube_url)
        
        logger.info(f"成功获取: {result['title']}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"错误: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400
```

**iiiLab 服务**: `backend/youtube_iiilab.py`
- 调用 iiiLab API 解析 YouTube 视频
- 提取多种清晰度的播放地址
- 提取字幕信息

---

## 日志输出示例

运行应用时，在 Xcode Console 中会看到：

```
============================================================
🎬 [WebView] 检测到 YouTube 视频！
📹 视频 ID: dQw4w9WgXcQ
🔗 原始 URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
🚀 准备拦截并跳转到应用内播放器...
============================================================

============================================================
🎬 开始加载 YouTube 视频
📹 Video ID: dQw4w9WgXcQ
📡 调用后端 API: /api/youtube-info/dQw4w9WgXcQ
============================================================

📡 [API] 请求 URL: https://littlesproutreading.onrender.com/api/youtube-info/dQw4w9WgXcQ
⏳ [API] 发送 HTTP 请求...
📥 [API] 收到响应: HTTP 200
✅ [API] 成功获取视频信息
   标题: How to use In, On, At in English
   格式数: 8
   字幕数: 2

📺 视频信息:
   标题: How to use In, On, At in English
   可用格式: 8 种
   [1] 720p - mp4 - 音频:有 - 分离:否
   [2] 480p - mp4 - 音频:有 - 分离:否
   [3] 360p - mp4 - 音频:有 - 分离:否
   ...

✅ 选择的格式:
   质量: 720p
   格式: mp4
   音频: 有
   播放地址: https://rr1---sn-aigllnls.googlevideo.com/videoplayback?...

🎬 开始加载视频...
✅ 视频就绪，可以播放
⬇️ 下载英文字幕: English
⬇️ 下载中文字幕: Chinese (Simplified)
✅ 加载了 156 条双语字幕
```

---

## 测试方法

### 1. 启动应用
```bash
cd /Users/yuxiaoyi/LittleSproutReading
open LittleSproutReading.xcodeproj
```

### 2. 运行并查看日志
- 点击 Run (Cmd + R)
- 打开 Console 查看日志

### 3. 测试步骤
1. 应用启动 → 显示 Ariannita la Gringa 频道
2. 点击任意视频
3. 查看 Console 日志，确认：
   - ✅ URL 被拦截
   - ✅ 提取了 video ID
   - ✅ 调用了后端 API
   - ✅ 获取了播放地址
   - ✅ 视频开始播放
   - ✅ 字幕加载成功

### 4. 预期结果
- 视频在应用内播放（不是在 WebView 中）
- 显示双语字幕
- 可以点击字幕跳转
- 可以翻译单词

---

## 常见问题

### Q1: WebView 中点击视频没反应
**检查**:
1. 查看 Console 是否有 "🎬 检测到 YouTube 视频" 日志
2. 确认 `YouTubeURLParser` 支持该 URL 格式
3. 检查 `decidePolicyFor` 是否被调用

### Q2: 视频无法播放
**检查**:
1. 查看后端 API 是否返回成功
2. 确认选择的格式有音频（`has_audio = true`）
3. 确认格式不是分离的（`separate = false`）
4. 检查 AVPlayer 的状态

### Q3: 字幕加载失败
**检查**:
1. 视频是否有字幕
2. 后端服务是否正常运行
3. 网络连接是否正常

### Q4: 后端 API 超时
**原因**: Render 免费版冷启动需要时间
**解决**: 等待 30-60 秒让服务启动

---

## 相关文件

### 前端（iOS）
- `LittleSproutReading/Views/YouTubeWebView.swift` - WebView 和 URL 拦截
- `LittleSproutReading/ViewModels/VideoPlayerViewModel.swift` - 视频播放逻辑
- `LittleSproutReading/Services/YouTubeSubtitleService.swift` - API 调用
- `LittleSproutReading/Services/YouTubeURLParser.swift` - URL 解析

### 后端（Python）
- `backend/app.py` - Flask API 服务器
- `backend/youtube_iiilab.py` - iiiLab 服务封装

---

## 技术栈

### 前端
- SwiftUI
- WebKit (WKWebView)
- AVFoundation (AVPlayer)
- Combine

### 后端
- Flask
- iiiLab API
- youtube-transcript-api

---

**创建日期**: 2025-12-23  
**最后更新**: 2025-12-23  
**版本**: 1.0

