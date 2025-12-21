# 《绝望主妇》字幕获取指南

## 问题说明

视频文件 `Desperate.Housewives.S01E07` 的字幕是**硬编码(烧录)**在画面上的,无法直接提取为SRT文件。

## 解决方案

### 方案1: 下载现成的SRT字幕文件(推荐)

#### 字幕网站:
1. **字幕库**: https://zimuku.org
   - 搜索: "绝望主妇 S01E07" 或 "Desperate Housewives S01E07"
   - 下载双语字幕(中英)

2. **射手网(伪)**: https://assrt.net
   - 搜索剧集名称和集数
   - 选择匹配的字幕文件

3. **SubHD**: https://subhd.tv
   - 美剧字幕资源丰富

#### 下载后:
```bash
# 将下载的字幕文件重命名并放入项目
mv ~/Downloads/Desperate.Housewives.S01E07.srt \
   /Users/yuxiaoyi/LittleSproutReading/LittleSproutReading/Resources/Subtitles/sample.srt
```

### 方案2: 使用AI生成字幕

如果找不到现成字幕,可以使用AI工具生成:

#### 使用Whisper(OpenAI语音识别):
```bash
# 安装whisper
pip install openai-whisper

# 提取音频
ffmpeg -i LittleSproutReading/Resources/Videos/sample.mp4 \
       -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav

# 生成字幕(英文)
whisper audio.wav --model medium --language en --output_format srt

# 生成的字幕会保存为 audio.srt
```

然后需要手动添加中文翻译,或使用翻译工具。

### 方案3: 临时测试方案(最简单)

使用项目已有的示例字幕先测试功能:

```bash
# 示例字幕已存在于:
# LittleSproutReading/Resources/Subtitles/sample.srt
```

虽然字幕内容与视频不匹配,但可以:
- ✅ 测试视频播放功能
- ✅ 测试逐字高亮效果
- ✅ 测试AI查词功能
- ✅ 验证所有UI和交互

## 推荐操作

**立即可用**: 直接运行应用,使用示例字幕测试所有功能

**获取真实字幕**: 从字幕库下载《绝望主妇》S01E07的双语字幕

## 字幕格式要求

下载的字幕需要是**双语SRT格式**:

```srt
1
00:00:00,000 --> 00:00:02,500
This is the English subtitle.
这是中文字幕。

2
00:00:02,500 --> 00:00:05,000
Another line of dialogue.
另一句对话。
```

如果下载的是单语字幕,需要手动合并中英文,或使用翻译工具。

## 快速测试

现在就可以在Xcode中运行应用:
1. 打开 `LittleSproutReading.xcodeproj`
2. 选择iPad模拟器
3. 按 ⌘R 运行
4. 视频会播放《绝望主妇》
5. 字幕会显示示例内容(训犬师的故事)

虽然字幕不匹配,但所有功能都可以正常测试!
