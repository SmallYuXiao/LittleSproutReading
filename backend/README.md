# YouTube 字幕服务

一个轻量级的 Flask 服务,用于获取 YouTube 视频字幕。

## 🚀 快速开始

### 1. 安装依赖

```bash
cd backend
pip3 install -r requirements.txt
```

### 2. 启动服务

```bash
python3 app.py
```

服务将在 `http://localhost:5000` 启动。

## 📖 API 文档

### 健康检查

```
GET /health
```

**响应示例**:
```json
{
  "status": "ok",
  "service": "YouTube Subtitle Service",
  "version": "1.0.0"
}
```

### 获取字幕

```
GET /api/subtitles/<video_id>?lang=en
```

**参数**:
- `video_id` (必需): YouTube 视频 ID
- `lang` (可选): 语言代码,默认 `en`

**响应示例**:
```json
{
  "success": true,
  "video_id": "dQw4w9WgXcQ",
  "language": "en",
  "language_name": "English",
  "is_generated": false,
  "subtitle_srt": "1\n00:00:00,000 --> 00:00:02,500\nHello world\n\n...",
  "subtitle_count": 150,
  "available_languages": [
    {
      "code": "en",
      "name": "English",
      "is_generated": false,
      "is_translatable": true
    }
  ]
}
```

### 获取可用语言

```
GET /api/languages/<video_id>
```

**响应示例**:
```json
{
  "success": true,
  "video_id": "dQw4w9WgXcQ",
  "languages": [
    {
      "code": "en",
      "name": "English",
      "is_generated": false,
      "is_translatable": true
    },
    {
      "code": "zh-Hans",
      "name": "Chinese (Simplified)",
      "is_generated": true,
      "is_translatable": false
    }
  ]
}
```

## 🧪 测试

### 使用 curl 测试

```bash
# 健康检查
curl http://localhost:5000/health

# 获取字幕
curl http://localhost:5000/api/subtitles/dQw4w9WgXcQ

# 获取中文字幕
curl http://localhost:5000/api/subtitles/dQw4w9WgXcQ?lang=zh-Hans

# 获取可用语言
curl http://localhost:5000/api/languages/dQw4w9WgXcQ
```

## 💡 使用说明

1. **完全免费**: 无需 API Key,无配额限制
2. **支持多语言**: 自动获取可用字幕语言
3. **SRT 格式**: 返回标准 SRT 格式字幕
4. **本地运行**: 数据安全,无隐私泄露

## ⚠️ 注意事项

- 仅支持有字幕的 YouTube 视频
- 某些受限视频可能无法获取字幕
- 建议在本地网络环境下使用
