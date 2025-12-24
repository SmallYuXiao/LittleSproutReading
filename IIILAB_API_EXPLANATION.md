# iiiLab API 详解

## 📖 什么是 iiiLab API？

**iiiLab** 是一个第三方视频解析服务平台，提供从 YouTube 等 1000+ 网站提取视频、音频和字幕的 API 接口。

### 官方信息
- **API 地址**: `https://api.snapany.com/v1/extract`
- **服务提供**: iiilab.com / snapany.com
- **开源项目**: iiiLabCrawler

---

## 🎯 在本项目中的作用

### 核心功能
在 LittleSproutReading 项目中，iiilab API 用于：

1. **获取 YouTube 视频的直接播放地址**
   - 解析 YouTube URL
   - 提取可直接播放的 MP4/WebM 视频流
   - 支持多种清晰度（720p, 480p, 360p 等）

2. **获取视频字幕信息**
   - 提取可用字幕列表
   - 获取字幕下载链接
   - 支持多语言字幕（英文、中文等）

3. **获取视频元数据**
   - 视频标题
   - 时长
   - 缩略图
   - 等等

---

## 🔄 工作流程

### 完整流程示例

```
用户在 iOS 应用中点击 YouTube 视频
  ↓
iOS 应用发送请求到你的后端
GET http://localhost:5001/api/youtube-info/dQw4w9WgXcQ
  ↓
你的后端服务器调用 iiilab API
POST https://api.snapany.com/v1/extract
Body: {"link": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}
Headers: {
  "G-Timestamp": 1703338800000,
  "G-Footer": "md5签名"
}
  ↓
iiilab API 返回解析结果
{
  "text": "视频标题",
  "duration": 212,
  "medias": [
    {
      "quality": "720p",
      "url": "https://rr1---sn-xxx.googlevideo.com/...",
      "hasAudio": true
    }
  ],
  "subtitles": [...]
}
  ↓
你的后端处理并转换格式
  ↓
返回给 iOS 应用
  ↓
iOS 应用使用 AVPlayer 播放视频
```

---

## 🔐 API 认证机制

### 签名算法
iiilab API 使用 MD5 签名进行认证：

```python
# 签名字符串格式
signature_string = url + language + timestamp + SALT

# 计算 MD5 哈希
signature = md5(signature_string).hexdigest()

# 请求头
headers = {
    'G-Timestamp': timestamp,  # 毫秒级时间戳
    'G-Footer': signature      # MD5 签名
}
```

### 参数说明
- **url**: YouTube 视频完整 URL
- **language**: 语言代码（默认 "en"）
- **timestamp**: Unix 毫秒时间戳
- **SALT**: 固定密钥 `"6HTugjCXxR"`

---

## 📊 API 响应示例

### 请求
```http
POST https://api.snapany.com/v1/extract
Content-Type: application/json
G-Timestamp: 1703338800000
G-Footer: abc123def456...

{
  "link": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

### 成功响应
```json
{
  "text": "Rick Astley - Never Gonna Give You Up",
  "duration": 212,
  "medias": [
    {
      "quality": "720p",
      "quality_value": 720,
      "quality_note": "HD",
      "format": "mp4",
      "url": "https://rr1---sn-xxx.googlevideo.com/videoplayback?...",
      "audio_url": null,
      "filesize": 15728640,
      "hasAudio": true,
      "height": 720,
      "separate": false
    },
    {
      "quality": "480p",
      "quality_value": 480,
      "url": "https://...",
      "hasAudio": true,
      "separate": false
    }
  ],
  "subtitles": [
    {
      "language": "en",
      "language_name": "English",
      "url": "https://www.youtube.com/api/timedtext?...",
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

## ⚠️ API 限制

### 1. 频率限制
```
错误信息: "Your operation is too frequent, please try again later"
错误代码: "ShowSponsorAds"
```

**原因**：
- 请求过于频繁
- 建议间隔至少 3 秒

**解决方案**：
- ✅ 添加请求频率控制
- ✅ 实现缓存机制
- ✅ 避免短时间内重复请求

### 2. 地区限制
某些视频可能因地区限制无法解析

### 3. 视频权限
私密视频或被删除的视频无法解析

---

## 🆚 为什么使用 iiilab API？

### vs 直接使用 YouTube API

| 特性 | iiilab API | YouTube API |
|------|-----------|------------|
| **视频直接播放** | ✅ 提供直接播放链接 | ❌ 需要 iframe 嵌入 |
| **字幕下载** | ✅ 直接下载链接 | ⚠️ 需要复杂认证 |
| **认证要求** | 简单签名 | OAuth 2.0 |
| **费用** | 免费 | 有配额限制 |
| **合规性** | ⚠️ 灰色地带 | ✅ 官方支持 |

### 优势
- ✅ **简单易用**：无需复杂的 OAuth 认证
- ✅ **直接播放**：可以获取视频的直接播放地址
- ✅ **免费**：无需 API Key 或付费
- ✅ **功能全面**：视频 + 字幕 + 元数据

### 劣势
- ⚠️ **稳定性**：第三方服务，可能随时失效
- ⚠️ **频率限制**：有请求频率限制
- ⚠️ **合规性**：可能违反 YouTube 服务条款
- ⚠️ **无官方支持**：出问题只能自己解决

---

## 🔧 在项目中的实现

### 文件位置
```
backend/
├── youtube_iiilab.py    # iiilab API 封装类
└── app.py              # Flask API 端点
```

### 核心代码
```python
class IIILabYouTubeService:
    BASE_URL = "https://api.snapany.com/v1/extract"
    SALT = "6HTugjCXxR"
    
    def extract_video_info(self, youtube_url: str) -> Dict:
        # 1. 生成签名
        timestamp = int(time.time() * 1000)
        signature = self._generate_signature(timestamp, youtube_url)
        
        # 2. 发送请求
        response = self.session.post(
            self.BASE_URL,
            json={"link": youtube_url},
            headers={
                'G-Timestamp': str(timestamp),
                'G-Footer': signature
            }
        )
        
        # 3. 解析响应
        return self._parse_response(response.json())
```

### Flask API 端点
```python
@app.route('/api/youtube-info/<video_id>', methods=['GET'])
def get_youtube_info(video_id):
    youtube_url = build_youtube_url(video_id)
    result = iiilab_service.extract_video_info(youtube_url)
    return jsonify(result)
```

---

## 🎓 使用建议

### 1. 实现缓存
```python
# 缓存 10 分钟
self.cache = {}
self.cache_ttl = 600
```

### 2. 频率控制
```python
# 请求间隔 3 秒
self.min_request_interval = 3.0
```

### 3. 错误处理
```python
try:
    result = api.extract_video_info(url)
except Exception as e:
    # 降级处理
    return fallback_method()
```

### 4. 备用方案
准备其他视频解析方案：
- yt-dlp（本地）
- YouTube Data API（官方）
- 其他第三方服务

---

## 📚 相关资源

- **官方网站**: https://iiilab.com
- **API 地址**: https://api.snapany.com
- **开源项目**: iiiLabCrawler (GitHub)

---

## ⚖️ 法律声明

**重要提示**：

1. iiilab API 用于解析 YouTube 视频可能**违反 YouTube 服务条款**
2. 仅供**学习和研究**使用
3. 不建议用于商业项目
4. 用户需自行承担法律风险

### 合法替代方案
- 使用 YouTube 官方 Data API
- 使用 YouTube IFrame Player
- 申请 YouTube Partner 项目

---

## 🎯 总结

iiilab API 是一个**第三方 YouTube 视频解析服务**，能够：

- ✅ 提取视频直接播放地址
- ✅ 获取字幕下载链接
- ✅ 免费且简单易用

但需要注意：
- ⚠️ 有频率限制（需要缓存和频率控制）
- ⚠️ 稳定性依赖第三方
- ⚠️ 可能违反 YouTube ToS

**对于学习项目来说是不错的选择，但生产环境建议使用官方 API。**

---

**创建日期**: 2025-12-23  
**版本**: 1.0  
**状态**: ✅ 已实施

