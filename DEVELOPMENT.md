# 小萌芽阅读 - 开发指南

## 项目概述

这是一个iPad英语学习应用,核心功能包括:
- 视频播放 + 双语字幕
- 逐字高亮(卡拉OK效果)
- AI智能查词
- 生词本管理

## 开发环境

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- iOS 16.0+

## 快速开始

### 1. 配置API Key

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑.env文件,填入你的vveai API Key
# VVEAI_API_KEY=your_api_key_here
```

### 2. 添加测试视频

将测试视频(mp4格式)放入 `Resources/Videos/` 目录,字幕文件(srt格式)放入 `Resources/Subtitles/` 目录。

### 3. 在Xcode中运行

```bash
# 如果有Xcode项目文件
open LittleSproutReading.xcodeproj

# 或者手动在Xcode中打开项目文件夹
```

选择iPad模拟器,点击运行。

## 核心功能实现

### 逐字高亮

字幕行组件 `SubtitleRow` 实现了逐字高亮效果:

1. 字幕解析时自动分词
2. 为每个单词计算时间范围
3. 根据播放时间动态改变单词颜色
4. 使用SwiftUI的HStack渲染单词列表

### AI查词

词典服务 `DictionaryService` 集成了vveai API:

1. 点击单词触发查询
2. 检查本地缓存
3. 调用AI API获取释义
4. 解析JSON响应
5. 显示翻译弹窗

### 视频同步

视频播放器 `VideoPlayerViewModel` 使用定时器实现精准同步:

1. 每0.1秒更新当前时间
2. 查找对应的字幕条目
3. 触发字幕自动滚动
4. 更新单词高亮状态

## 文件说明

### 数据模型
- `Subtitle.swift`: 字幕数据模型,包含单词时间信息
- `Video.swift`: 视频资源模型
- `SubtitleParser.swift`: SRT字幕解析器
- `WordDefinition.swift`: 单词释义模型

### 服务层
- `DictionaryService.swift`: 词典服务,AI查词、发音、生词本

### ViewModel
- `VideoPlayerViewModel.swift`: 视频播放器状态管理

### 视图组件
- `ContentView.swift`: 主视图,横屏布局
- `VideoPlayerView.swift`: 视频播放器
- `SubtitleListView.swift`: 字幕列表
- `SubtitleRow.swift`: 单条字幕(逐字高亮)
- `WordTranslationPopup.swift`: 翻译弹窗

## 常见问题

### Q: 如何添加新的视频?

A: 将视频文件(mp4)和对应的字幕文件(srt)放入Resources目录,然后在 `Video.swift` 中添加新的视频模型。

### Q: 如何修改字幕格式?

A: 编辑 `SubtitleParser.swift`,添加新的解析方法(如VTT、JSON等)。

### Q: 如何更换AI服务?

A: 修改 `DictionaryService.swift` 中的API调用逻辑,只需保持 `WordDefinition` 数据结构不变即可。

### Q: 如何调整逐字高亮的颜色?

A: 修改 `SubtitleRow.swift` 中的 `WordState.color` 属性。

## 调试技巧

### 查看字幕解析结果

在 `SubtitleParser.swift` 中添加打印语句:

```swift
print("✅ 解析字幕: \(subtitle.englishText)")
print("   单词数: \(subtitle.words.count)")
```

### 查看API请求

在 `DictionaryService.swift` 中添加:

```swift
print("🔍 查询单词: \(word)")
print("📡 API响应: \(content)")
```

### 查看播放时间

在 `VideoPlayerViewModel.swift` 中:

```swift
print("⏱️ 当前时间: \(currentTime), 字幕索引: \(currentSubtitleIndex ?? -1)")
```

## 性能优化

1. **缓存机制**: 已查询的单词会缓存到内存,避免重复请求
2. **懒加载**: 字幕列表使用 `LazyVStack` 优化渲染性能
3. **定时器优化**: 使用0.1秒间隔平衡精度和性能

## 下一步开发

- [ ] 添加视频列表页面
- [ ] 实现字幕搜索功能
- [ ] 支持播放速度调节
- [ ] 添加学习进度统计
- [ ] 实现生词本复习功能

---

**Happy Coding! 🚀**
