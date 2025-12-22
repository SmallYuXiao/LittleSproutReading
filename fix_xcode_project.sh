#!/bin/bash

echo "🔧 修复 Xcode 项目配置"
echo "========================"

PROJECT_DIR="/Users/yuxiaoyi/LittleSproutReading"
PROJECT_FILE="$PROJECT_DIR/LittleSproutReading.xcodeproj/project.pbxproj"

echo "📝 项目文件: $PROJECT_FILE"

# 提示用户手动操作
echo ""
echo "⚠️  需要在 Xcode 中手动添加以下文件:"
echo ""
echo "Services 文件夹:"
echo "  ✓ YouTubeURLParser.swift"
echo "  ✓ YouTubeSubtitleService.swift"
echo ""
echo "Views 文件夹:"
echo "  ✓ YouTubePlayerView.swift"
echo "  ✓ YouTubeInputView.swift"
echo ""
echo "📖 操作步骤:"
echo "1. 在 Xcode 中右键点击 'Services' 文件夹"
echo "2. 选择 'Add Files to LittleSproutReading...'"
echo "3. 选择上述两个 Services 文件"
echo "4. 确保勾选 'Add to targets: LittleSproutReading'"
echo "5. 对 Views 文件夹重复相同操作"
echo ""
echo "或者,直接在 Xcode 中:"
echo "1. 选中项目根目录"
echo "2. 按 ⌘+⌥+A (Add Files)"
echo "3. 选择所有新文件"
echo ""
