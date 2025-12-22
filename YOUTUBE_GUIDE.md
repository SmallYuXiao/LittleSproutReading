# YouTube 实时字幕学习功能 - 使用指南

## 🎯 功能概述

LittleSproutReading 现已支持 YouTube 视频学习!你可以:
- 输入任意 YouTube 视频链接
- 自动获取视频字幕
- 享受逐字高亮的学习体验
- 点击单词查询释义

## 🚀 快速开始

### 步骤 1: 启动后端服务

打开终端,进入项目目录:

```bash
cd /Users/yuxiaoyi/LittleSproutReading/backend
./start.sh
```

或者手动启动:

```bash
cd backend
pip3 install -r requirements.txt
python3 app.py
```

看到以下信息表示服务启动成功:

```
============================================================
🚀 YouTube 字幕服务已启动
============================================================
📍 服务地址: http://localhost:5000
```

**⚠️ 重要**: 使用 YouTube 功能时,请保持此服务运行!

### 步骤 2: 运行 iOS 应用

1. 在 Xcode 中打开项目
2. 选择 iPad 模拟器或真机
3. 点击运行 (⌘R)

### 步骤 3: 使用 YouTube 功能

1. 在应用中点击 **YouTube** 标签
2. 输入 YouTube 视频链接,例如:
   - `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
   - `https://youtu.be/dQw4w9WgXcQ`
3. 点击 **加载视频** 按钮
4. 等待字幕加载完成
5. 开始学习!

## 📖 使用说明

### 支持的 URL 格式

- ✅ `https://www.youtube.com/watch?v=VIDEO_ID`
- ✅ `https://youtu.be/VIDEO_ID`
- ✅ `https://m.youtube.com/watch?v=VIDEO_ID`
- ✅ `https://www.youtube.com/embed/VIDEO_ID`

### 字幕功能

- **自动获取**: 自动下载视频的英文字幕
- **逐字高亮**: 播放时单词逐个变绿色
- **点击查词**: 点击任意单词查看 AI 翻译
- **字幕同步**: 支持字幕偏移调节(±0.5秒)

### 视频控制

- **播放/暂停**: 点击播放按钮
- **进度控制**: YouTube 播放器内置进度条
- **跳转**: 点击字幕跳转到对应时间

## 🔧 故障排除

### 问题 1: 无法加载字幕

**错误信息**: "网络错误" 或 "服务器错误"

**解决方案**:
1. 确认后端服务正在运行
2. 在浏览器中访问 `http://localhost:5000/health` 检查服务状态
3. 检查视频是否有字幕(某些视频没有字幕)

### 问题 2: 无效的 YouTube URL

**错误信息**: "无效的 YouTube URL"

**解决方案**:
1. 检查 URL 格式是否正确
2. 确保 URL 包含完整的视频 ID
3. 尝试从浏览器地址栏复制完整 URL

### 问题 3: 该视频没有可用的字幕

**错误信息**: "该视频没有可用的字幕"

**解决方案**:
1. 在 YouTube 网站上确认视频是否有字幕
2. 尝试其他有字幕的视频
3. 某些受限视频可能无法获取字幕

### 问题 4: 后端服务无法启动

**错误信息**: "未找到 Python 3" 或依赖安装失败

**解决方案**:
1. 安装 Python 3: `brew install python3`
2. 手动安装依赖: `pip3 install flask flask-cors youtube-transcript-api`
3. 检查网络连接

## 💡 使用技巧

### 1. 选择合适的学习视频

推荐选择:
- ✅ 有官方字幕的视频(更准确)
- ✅ 语速适中的教育类视频
- ✅ TED 演讲、纪录片等

避免:
- ❌ 音乐视频(字幕可能不准确)
- ❌ 语速过快的视频
- ❌ 无字幕的视频

### 2. 字幕同步调节

如果字幕与视频不同步:
- 字幕提前: 点击 `-` 按钮延迟字幕
- 字幕延迟: 点击 `+` 按钮提前字幕
- 每次调节 0.5 秒

### 3. 高效学习流程

1. **第一遍**: 完整观看,了解大意
2. **第二遍**: 关注逐字高亮,学习发音
3. **第三遍**: 点击生词查询释义
4. **复习**: 使用生词本复习

## 🎓 推荐学习资源

### YouTube 频道推荐

- **TED**: 高质量演讲,字幕准确
- **BBC Learning English**: 专为英语学习者设计
- **Crash Course**: 教育类视频,语速适中
- **National Geographic**: 纪录片,词汇丰富

### 示例视频

```
TED Talk 示例:
https://www.youtube.com/watch?v=8S0FDjFBj8o

BBC Learning English:
https://www.youtube.com/watch?v=yjhibJ-OqxE
```

## 📊 技术说明

### 后端服务

- **框架**: Flask (Python)
- **字幕库**: youtube-transcript-api
- **端口**: 5000
- **API**: RESTful

### iOS 客户端

- **播放器**: WKWebView + YouTube iFrame API
- **字幕显示**: 原生 SwiftUI
- **网络**: URLSession

### 数据流程

```
用户输入 URL → 解析 Video ID → 调用后端 API → 
获取字幕 → 解析 SRT → 显示逐字高亮
```

## 🔒 隐私说明

- ✅ 所有数据处理在本地完成
- ✅ 不上传任何个人信息
- ✅ 字幕数据不存储
- ✅ 符合 YouTube 服务条款

## 📝 已知限制

1. **视频播放**: 必须通过 YouTube 播放器(符合服务条款)
2. **字幕语言**: 目前仅支持英文字幕
3. **网络要求**: 需要稳定的网络连接
4. **视频限制**: 某些受限/私有视频无法访问

## 🚧 后续计划

- [ ] 支持多语言字幕选择
- [ ] 支持双语字幕显示
- [ ] 字幕缓存功能
- [ ] YouTube 视频搜索
- [ ] 播放历史记录

---

**祝你学习愉快!** 🎉

如有问题,请查看故障排除部分或联系开发者。
