# YouTube API Server 部署到 Render 指南

## 📋 概述

将 `youtube-api-server` 部署到 Render,作为字幕获取的备选方案。

---

## 🚀 部署步骤

### 1️⃣ Fork 仓库

1. 访问: https://github.com/zaidmukaddam/youtube-api-server
2. 点击右上角 **Fork** 按钮
3. Fork 到您的 GitHub 账号

---

### 2️⃣ 在 Fork 的仓库中添加 Render 配置

在您 fork 的仓库根目录创建 `render.yaml` 文件:

```yaml
services:
  - type: web
    name: youtube-api-server
    env: python
    region: singapore
    plan: free
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
    healthCheckPath: /health
    envVars:
      - key: PYTHON_VERSION
        value: 3.12.0
      - key: PORT
        value: 8000
      - key: HOST
        value: 0.0.0.0
```

**如何添加**:
1. 在 GitHub 仓库页面,点击 **Add file** → **Create new file**
2. 文件名输入: `render.yaml`
3. 复制上面的内容粘贴进去
4. 点击 **Commit new file**

---

### 3️⃣ 连接到 Render

1. 登录 Render: https://dashboard.render.com/
2. 点击 **New** → **Web Service**
3. 选择 **Connect a repository**
4. 找到您 fork 的 `youtube-api-server` 仓库
5. 点击 **Connect**

---

### 4️⃣ 配置服务

Render 会自动检测到 `render.yaml` 文件:

1. **Name**: `youtube-api-server` (自动填充)
2. **Region**: Singapore (自动填充)
3. **Branch**: `main` (默认)
4. **Build Command**: 自动填充
5. **Start Command**: 自动填充
6. 点击 **Create Web Service**

---

### 5️⃣ 等待部署

- 部署需要 **5-10 分钟**
- 您可以在 Render Dashboard 查看部署日志
- 部署成功后,会显示服务 URL

---

## 🔍 测试 API

部署完成后,您会得到一个 URL,例如:
```
https://youtube-api-server-xxxx.onrender.com
```

### 测试健康检查

```bash
curl https://youtube-api-server-xxxx.onrender.com/health
```

**预期响应**:
```json
{
  "status": "healthy",
  "service": "YouTube API Server",
  "version": "1.0.0"
}
```

### 测试获取字幕

```bash
curl -X POST "https://youtube-api-server-xxxx.onrender.com/video-timestamps" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "languages": ["en"]}'
```

**预期响应**:
```json
{
  "video_id": "dQw4w9WgXcQ",
  "language": "en",
  "timestamps": [
    {
      "text": "We're no strangers to love",
      "start": 0.0,
      "duration": 3.5
    },
    ...
  ]
}
```

---

## 📝 记录服务 URL

部署成功后,请记录您的服务 URL:

```
https://youtube-api-server-xxxx.onrender.com
```

**下一步**: 将这个 URL 告诉我,我会帮您集成到 iOS App 中!

---

## ⚠️ 注意事项

### Render 免费 tier 限制

- ✅ 每月 750 小时免费运行时间
- ⚠️ 15 分钟无活动后会休眠
- ⚠️ 首次请求可能需要 30-60 秒唤醒

### 休眠问题解决方案

如果您希望服务保持活跃,可以:

1. **升级到付费计划** ($7/月)
2. **使用定时 ping 服务** (例如 UptimeRobot)
3. **接受首次请求较慢** (推荐,免费方案)

---

## 🐛 常见问题

### 问题 1: 部署失败

**原因**: Python 版本不匹配

**解决**: 确保 `render.yaml` 中的 Python 版本是 `3.12.0`

### 问题 2: Health check 失败

**原因**: 启动命令错误

**解决**: 确保 `startCommand` 是:
```
uvicorn main:app --host 0.0.0.0 --port $PORT
```

### 问题 3: 字幕获取失败

**原因**: YouTube 可能封锁了 Render 的 IP

**解决**: 
- 等待几分钟重试
- 或配置 Webshare 代理 (需要注册账号)

---

## ✅ 部署完成检查清单

- [ ] Fork 了 youtube-api-server 仓库
- [ ] 添加了 `render.yaml` 配置文件
- [ ] 在 Render 创建了 Web Service
- [ ] 部署成功 (状态显示 "Live")
- [ ] Health check 通过
- [ ] 测试了字幕获取 API
- [ ] 记录了服务 URL

**完成后,请将服务 URL 告诉我,我会立即集成到 App 中!** 🚀

---

## 📚 相关文档

- Render 官方文档: https://render.com/docs
- youtube-api-server GitHub: https://github.com/zaidmukaddam/youtube-api-server
- FastAPI 文档: https://fastapi.tiangolo.com/
