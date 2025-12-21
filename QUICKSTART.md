# 快速开始指南

## 📦 项目已就绪

Xcode项目文件已创建完成,可以直接打开使用!

## 🚀 三步开始

### 1️⃣ 打开项目

```bash
cd /Users/yuxiaoyi/LittleSproutReading
open LittleSproutReading.xcodeproj
```

或在Finder中双击 `LittleSproutReading.xcodeproj`

### 2️⃣ 配置API Key

```bash
# 复制环境变量文件
cp .env.example .env

# 编辑.env文件,填入你的API Key
# VVEAI_API_KEY=your_api_key_here
```

### 3️⃣ 添加测试视频

将测试视频(mp4格式)放入:
```
LittleSproutReading/Resources/Videos/sample.mp4
```

已提供示例字幕: `Resources/Subtitles/sample.srt`

## ▶️ 运行应用

1. 在Xcode中选择iPad模拟器(建议iPad Pro 12.9")
2. 点击运行按钮(⌘R)
3. 等待编译完成

## ✅ 测试功能

- [ ] 视频播放
- [ ] 字幕同步
- [ ] 逐字高亮(卡拉OK效果)
- [ ] 点击单词查词
- [ ] 语音发音
- [ ] 生词本收藏

## ⚠️ 注意事项

1. **API Key必填**: 未配置会导致查词功能报错
2. **视频格式**: 必须是mp4格式
3. **字幕格式**: 必须是SRT格式,英文和中文分行
4. **横屏模式**: 应用仅支持横屏,请在iPad上测试

## 📚 更多文档

- [README.md](README.md) - 完整项目说明
- [DEVELOPMENT.md](DEVELOPMENT.md) - 开发指南
- [walkthrough.md](.gemini/antigravity/brain/d84601d1-9a1f-4269-943d-0a8defd07c91/walkthrough.md) - 开发总结

---

**开始你的英语学习之旅吧! 🎉**
