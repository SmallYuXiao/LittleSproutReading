# 视频资源加载问题修复指南

## 问题原因

Xcode项目中的资源文件需要正确添加到项目中才能被Bundle加载。

## 解决方案

### 方法1: 在Xcode中添加资源文件(推荐)

1. 在Xcode中,右键点击项目导航器中的 `LittleSproutReading` 文件夹
2. 选择 **Add Files to "LittleSproutReading"...**
3. 导航到 `LittleSproutReading/Resources` 文件夹
4. 选中 `Resources` 文件夹
5. 确保勾选:
   - ✅ **Copy items if needed**
   - ✅ **Create folder references** (重要!)
   - ✅ Target: LittleSproutReading
6. 点击 **Add**

### 方法2: 检查Build Phases

1. 在Xcode中选择项目
2. 选择Target: LittleSproutReading
3. 进入 **Build Phases** 标签
4. 展开 **Copy Bundle Resources**
5. 点击 **+** 添加资源:
   - `Resources/Videos/sample.mp4`
   - `Resources/Subtitles/sample.srt`

### 方法3: 使用文档目录(临时方案)

如果上述方法不行,可以将视频文件复制到应用的文档目录:

```swift
// 在VideoPlayerViewModel中添加
private func copyResourceToDocuments() {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    // 复制视频
    let videoSource = "/Users/yuxiaoyi/LittleSproutReading/LittleSproutReading/Resources/Videos/sample.mp4"
    let videoDestination = documentsURL.appendingPathComponent("sample.mp4")
    
    if !fileManager.fileExists(atPath: videoDestination.path) {
        try? fileManager.copyItem(atPath: videoSource, to: videoDestination)
    }
}
```

## 验证资源是否正确添加

在 `VideoPlayerViewModel.swift` 的 `loadVideo` 方法中添加调试信息:

```swift
func loadVideo(_ video: Video) {
    print("🎬 尝试加载视频: \(video.fileName)")
    print("📁 Bundle路径: \(Bundle.main.resourcePath ?? "未知")")
    print("📹 视频URL: \(video.videoURL?.path ?? "未找到")")
    print("📝 字幕URL: \(video.subtitleURL?.path ?? "未找到")")
    
    guard let videoURL = video.videoURL else {
        print("❌ 视频文件不存在: \(video.fileName)")
        return
    }
    // ... 其余代码
}
```

## 当前状态

- ✅ Info.plist已更新(支持所有方向)
- ✅ Video.swift已更新(增强资源查找逻辑)
- ⚠️ 需要在Xcode中手动添加Resources文件夹引用

## 下一步

1. 在Xcode中添加Resources文件夹引用
2. 重新编译项目
3. 运行应用测试
