# YouTube 官方 SDK 集成指南

## 步骤 1: 添加 Swift Package 依赖

### 在 Xcode 中操作:

1. **打开项目**: 在 Xcode 中打开 `LittleSproutReading.xcodeproj`

2. **添加 Package**:
   - 点击项目导航器中的项目根目录
   - 选择 **"LittleSproutReading"** 项目(蓝色图标)
   - 点击顶部的 **"Package Dependencies"** 标签
   - 点击左下角的 **"+"** 按钮

3. **输入 Package URL**:
   ```
   https://github.com/SvenTiigi/YouTubePlayerKit.git
   ```

4. **选择版本**:
   - Dependency Rule: **"Up to Next Major Version"**
   - Version: **1.0.0** (或最新版本)

5. **点击 "Add Package"**

6. **选择 Target**:
   - 确保勾选 **"LittleSproutReading"**
   - 点击 **"Add Package"**

7. **等待下载完成**

## 步骤 2: 验证安装

安装完成后,你应该在项目导航器中看到:
- **Package Dependencies** 下有 **YouTubePlayerKit**

## 步骤 3: 准备更新代码

完成上述步骤后,告诉我,我会帮你更新代码!

---

**提示**: 如果遇到网络问题,可能需要等待几分钟让 Xcode 下载依赖。
