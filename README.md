# 小萌芽阅读 (LittleSproutReading)

一个专为iPad设计的英语学习应用,通过视频+双语字幕的方式帮助用户提升英语水平。

## ✨ 核心功能

### 📺 视频播放
- 支持本地视频播放
- 流畅的播放控制(播放/暂停/进度条)
- 16:9 视频比例优化

### 🎯 逐字高亮字幕
- **卡拉OK效果**: 字幕逐字变绿色,跟随播放进度
- **精准同步**: 0.1秒级别的时间同步
- **双语显示**: 英文+中文翻译
- **左侧进度条**: 绿色进度条实时显示播放进度
- **自动滚动**: 当前字幕自动滚动到可见区域

### 🔍 AI智能查词
- **点击查词**: 点击任意单词即可查询释义
- **AI翻译**: 集成vveai API,提供准确的单词释义
- **语音发音**: 支持单词朗读
- **生词本**: 收藏生词,方便复习

### 📱 iPad横屏优化
- 左侧视频播放器(60%宽度)
- 右侧字幕列表(40%宽度)
- 深色主题,护眼舒适

## 🛠️ 技术栈

- **开发语言**: Swift
- **UI框架**: SwiftUI
- **视频播放**: AVFoundation (AVPlayer)
- **AI服务**: vveai API (OpenAI兼容)
- **架构模式**: MVVM
- **最低版本**: iOS 16.0+

## 📦 项目结构

```
LittleSproutReading/
├── App/
│   └── LittleSproutReadingApp.swift    # 应用入口
├── Models/
│   ├── Subtitle.swift                  # 字幕数据模型
│   ├── Video.swift                     # 视频资源模型
│   ├── SubtitleParser.swift            # 字幕解析器
│   └── WordDefinition.swift            # 单词释义模型
├── Services/
│   └── DictionaryService.swift         # 词典服务(AI查词)
├── ViewModels/
│   └── VideoPlayerViewModel.swift      # 视频播放器ViewModel
├── Views/
│   ├── ContentView.swift               # 主视图
│   ├── VideoPlayerView.swift           # 视频播放器视图
│   └── SubtitleListView.swift          # 字幕列表视图
├── Components/
│   ├── SubtitleRow.swift               # 字幕行组件
│   └── WordTranslationPopup.swift      # 翻译弹窗组件
└── Resources/
    ├── Videos/                         # 视频文件
    └── Subtitles/                      # 字幕文件(.srt)
```

## 🚀 快速开始

### 1. 配置环境变量

复制 `.env.example` 为 `.env` 并填写你的API Key:

```bash
cp .env.example .env
```

编辑 `.env` 文件:

```env
VVEAI_API_KEY=your_api_key_here
VVEAI_API_BASE_URL=https://api.vveai.com/v1
```

### 2. 添加测试资源

将你的视频文件放入 `Resources/Videos/` 目录,字幕文件放入 `Resources/Subtitles/` 目录。

**字幕格式示例** (SRT):

```srt
1
00:00:00,000 --> 00:00:02,500
Hi, I'm Chloe and I'm seven years old.
嗨,我是克洛伊,今年七岁

2
00:00:02,500 --> 00:00:05,000
I'm a dog trainer.
我是一名训犬师
```

### 3. 在Xcode中打开项目

```bash
open LittleSproutReading.xcodeproj
```

### 4. 配置横屏支持

在Xcode中:
1. 选择项目 → Target → General
2. Deployment Info → Device Orientation
3. 只勾选 **Landscape Left** 和 **Landscape Right**

### 5. 运行应用

选择iPad模拟器或真机,点击运行(⌘R)。

## 📝 使用说明

### 视频播放
- 点击播放按钮开始播放
- 拖动进度条跳转到指定位置

### 字幕交互
- **查看字幕**: 右侧自动显示双语字幕
- **逐字高亮**: 播放时单词逐个变绿色
- **点击跳转**: 点击任意字幕跳转到对应时间
- **点击查词**: 点击任意单词查看释义

### 单词翻译
- 点击单词后弹出翻译卡片
- 点击🔊发音按钮朗读单词
- 点击⭐收藏按钮添加到生词本
- 点击外部区域关闭弹窗

## 🎨 核心特性

### 逐字高亮实现原理

1. **分词**: 字幕解析时将句子按空格分割成单词数组
2. **时间计算**: 为每个单词计算时间范围(假设均匀分布)
3. **状态判断**: 根据当前播放时间判断单词状态
   - 未播放: 白色
   - 正在播放: 绿色加粗
   - 已播放: 绿色
4. **动态渲染**: 使用HStack将单词拼接,每个单词独立渲染颜色

### AI查词流程

1. 用户点击单词
2. 检查本地缓存
3. 调用vveai API查询释义
4. 解析JSON响应
5. 显示翻译结果
6. 缓存结果避免重复查询

## 🔧 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `VVEAI_API_KEY` | vveai API密钥 | 必填 |
| `VVEAI_API_BASE_URL` | API基础URL | `https://api.vveai.com/v1` |
| `API_TIMEOUT` | 请求超时时间(秒) | 30 |
| `CACHE_EXPIRATION` | 缓存过期时间(秒) | 86400 |

### 支持的字幕格式

目前支持 **SRT** 格式,要求:
- 英文和中文分行显示
- 时间格式: `00:00:00,000`
- 使用空行分隔字幕块

## 📚 后续扩展

- [ ] 视频列表页面
- [ ] 字幕搜索功能
- [ ] 播放速度调节
- [ ] 字幕导出功能
- [ ] 更多AI功能(句子翻译、语法分析)
- [ ] 后端API集成
- [ ] 用户学习进度追踪
- [ ] 生词本复习功能(间隔重复算法)
- [ ] 离线模式支持

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request!

---

**Made with ❤️ for English learners**
