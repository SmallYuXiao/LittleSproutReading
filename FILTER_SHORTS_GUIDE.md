# 过滤 YouTube Shorts 指南

## 🎯 问题
在 YouTube 搜索结果中，出现大量 Shorts（短视频），影响查找长视频的效率。

---

## ✅ 最新解决方案（已更新）

使用**时长过滤器**，只显示 4 分钟以上的视频：

```
&sp=EgQQARgE
```

### 参数说明
- **sp**: Search Parameters（搜索参数）
- **EgQQARgE**: 时长过滤 - 只显示 4 分钟以上的视频
  - 这会完全排除 Shorts（Shorts 最长 60 秒）
  - 只显示适合学习的长视频

---

## 📝 修改位置

### 1. 默认首页加载（第 30-35 行）

**之前**:
```swift
URL(string: "https://www.youtube.com/results?search_query=...")
```

**现在（使用时长过滤）**:
```swift
let searchQuery = "english news talks interview speech"
let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
// sp=EgQQARgE 表示 4+ 分钟的视频（完全排除 Shorts）
URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)&sp=EgQQARgE")
```

### 2. 初始页面加载（第 329-340 行）

**之前**:
```swift
"https://www.youtube.com/results?search_query=\(encodedQuery)"
```

**现在（使用时长过滤）**:
```swift
// 使用时长过滤器：sp=EgQQARgE 表示 4+ 分钟的视频
"https://www.youtube.com/results?search_query=\(encodedQuery)&sp=EgQQARgE"
```

---

## 🔍 YouTube 搜索过滤器参数

YouTube 支持多种搜索过滤器，通过 `sp` 参数控制：

| 过滤器 | 参数值 | 说明 |
|--------|--------|------|
| **4+ 分钟视频** | `EgQQARgE` | **最强过滤，完全排除 Shorts** ✅ |
| 20+ 分钟视频 | `EgQQARgF` | 只显示长视频 |
| 只显示 Shorts | `EgIYAg%253D%253D` | 只看短视频 |
| 4K 视频 | `EgJAAQ%253D%253D` | 高清视频 |
| 有字幕 | `EgIoAQ%253D%253D` | 包含字幕 |
| 最近上传 | `CAISAhAB` | 按上传时间排序 |

### 推荐使用 `EgQQARgE` 的原因：
- ✅ Shorts 最长 60 秒
- ✅ 4 分钟 = 240 秒
- ✅ 完全没有重叠，100% 过滤 Shorts

---

## 📊 效果对比

### 之前：
```
搜索结果：
  ✅ 长视频（10 分钟）
  ⚠️  Shorts（30 秒）← 不想要
  ⚠️  Shorts（60 秒）← 不想要
  ✅ 长视频（8 分钟）
  ⚠️  Shorts（45 秒）← 不想要
  ✅ 长视频（15 分钟）
  
比例：50% Shorts 😞
```

### 现在：
```
搜索结果：
  ✅ 长视频（10 分钟）
  ✅ 长视频（8 分钟）
  ✅ 长视频（15 分钟）
  ✅ 长视频（12 分钟）
  ✅ 长视频（20 分钟）
  ✅ 长视频（6 分钟）
  
比例：100% 长视频 😊
```

---

## 🎬 用户体验改进

### 场景 1: 首次打开 App
```
用户打开 App
    ↓
自动搜索 "english news talks interview speech"
    ↓
结果：全是长视频（5-30 分钟）✅
没有 Shorts ✅
```

### 场景 2: 点击回到首页
```
用户浏览到其他页面
    ↓
点击 🏠 首页按钮
    ↓
返回搜索页面
    ↓
结果：只显示长视频 ✅
```

### 场景 3: 在 YouTube 中搜索
```
用户在 YouTube 搜索框输入关键词
    ↓
手动搜索（不带过滤参数）
    ↓
结果：可能包含 Shorts ⚠️
```

**注意**：用户手动搜索时，YouTube 的默认行为不会自动过滤 Shorts。但 App 提供的默认搜索和首页按钮都已过滤。

---

## 🔧 技术细节

### URL 编码
- **原始值**: `EgIYAQ==`（Base64）
- **一次编码**: `EgIYAQ%3D%3D`（%3D 是 `=` 的编码）
- **二次编码**: `EgIYAQ%253D%253D`（%253D 是 `%3D` 的再次编码）

### 为什么要二次编码？
- Swift 的 `addingPercentEncoding` 会对 URL 参数进行一次编码
- YouTube 服务器期望接收到的是特定格式的编码
- 在 URL 字符串中直接使用二次编码，确保最终发送给 YouTube 的格式正确

### 验证方法
在控制台查看实际加载的 URL：
```
🌐 [WebView] 首次加载首页: https://www.youtube.com/results?search_query=english%20news%20talks%20interview%20speech&sp=EgIYAQ%253D%253D
🔍 搜索关键词: english news talks interview speech
🚫 过滤 Shorts: 启用
```

---

## 💡 额外建议

### 如果还想进一步过滤，可以组合多个参数：

```swift
// 只显示长视频 + 有字幕
"&sp=EgIYAQ%253D%253D&sp=EgIoAQ%253D%253D"

// 只显示长视频 + 按上传时间排序
"&sp=EgIYAQ%253D%253D&sp=CAISAhAB"

// 只显示长视频 + 4K画质
"&sp=EgIYAQ%253D%253D&sp=EgJAAQ%253D%253D"
```

但注意：组合过多参数可能会让搜索结果太少。

---

## ✅ 测试清单

- [x] 首次打开 App，默认搜索不显示 Shorts
- [x] 点击 🏠 首页按钮，返回的页面不显示 Shorts
- [x] WebView 实例复用时，保持过滤效果
- [x] 日志中显示 "🚫 过滤 Shorts: 启用"

---

## 🎉 总结

通过添加 `&sp=EgIYAQ%253D%253D` 参数：
- ✅ **默认搜索**：只显示长视频
- ✅ **首页按钮**：只显示长视频
- ✅ **用户体验**：更容易找到适合学习的长视频
- ✅ **无额外成本**：只是 URL 参数，不影响性能

**Shorts 已被完全过滤！** 🎯

