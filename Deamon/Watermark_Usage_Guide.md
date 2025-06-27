# LiveWallpaper 水印功能使用指南

## 概述

LiveWallpaper现在支持在动态壁纸上显示自定义文字水印，可以用于品牌展示、版权信息或个人标识。

## 功能特性

### 🎨 **水印样式**
- **自定义文字**：可以设置任意文字内容
- **多种位置**：支持5个位置（左上、右上、左下、右下、居中）
- **可调透明度**：0.0-1.0之间的透明度设置
- **背景支持**：可选的半透明背景
- **字体样式**：系统字体，支持不同大小

### 📍 **位置选项**
- `topLeft` - 左上角
- `topRight` - 右上角
- `bottomLeft` - 左下角
- `bottomRight` - 右下角（默认）
- `center` - 屏幕中央

## 使用方法

### 1. 基本用法

```bash
# 使用默认水印（右下角显示"LiveWallpaper"）
./wallpaperdeamon video.mp4 frame.png

# 自定义水印文字
./wallpaperdeamon video.mp4 frame.png "My Company"

# 自定义位置
./wallpaperdeamon video.mp4 frame.png "My Company" center

# 完整参数
./wallpaperdeamon video.mp4 frame.png false 0.0 "My Watermark" bottomRight true
```

### 2. 参数说明

```bash
./wallpaperdeamon <video_path> <frame_path> [enable_audio] [volume] [watermark_text] [watermark_position] [show_watermark]
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `video_path` | 视频文件路径 | 必需 |
| `frame_path` | 静态帧输出路径 | 必需 |
| `enable_audio` | 是否启用音频 | false |
| `volume` | 音量大小 (0.0-1.0) | 0.0 |
| `watermark_text` | 水印文字内容 | "LiveWallpaper" |
| `watermark_position` | 水印位置 | "bottomRight" |
| `show_watermark` | 是否显示水印 | true |

### 3. 使用示例

#### 品牌展示
```bash
# 在右下角显示公司名称
./wallpaperdeamon company_video.mp4 frame.png "Acme Corp" bottomRight

# 在左上角显示品牌标识
./wallpaperdeamon brand_video.mp4 frame.png "BRAND" topLeft
```

#### 版权信息
```bash
# 在左下角显示版权信息
./wallpaperdeamon video.mp4 frame.png "© 2025 My Company" bottomLeft

# 在中央显示版权信息
./wallpaperdeamon video.mp4 frame.png "All Rights Reserved" center
```

#### 个人标识
```bash
# 在右上角显示个人标识
./wallpaperdeamon personal_video.mp4 frame.png "Made by John" topRight

# 禁用水印
./wallpaperdeamon video.mp4 frame.png "No Watermark" bottomRight false
```

## 编程接口

### 水印配置结构体

```swift
struct WatermarkConfig {
    let text: String                    // 水印文字
    let fontSize: CGFloat              // 字体大小
    let fontColor: NSColor             // 字体颜色
    let backgroundColor: NSColor?      // 背景颜色（可选）
    let position: WatermarkPosition    // 位置
    let opacity: CGFloat               // 透明度
    let padding: CGFloat               // 内边距
}
```

### 控制方法

```swift
// 更新水印文字
daemon.updateWatermarkText("New Text")

// 更新透明度
daemon.updateWatermarkOpacity(0.5)

// 显示/隐藏水印
daemon.showWatermark(false)

// 更新完整配置
let newConfig = WatermarkConfig(...)
daemon.updateWatermarkConfig(newConfig)
```

## 样式定制

### 默认样式
- **字体**：系统字体，中等粗细
- **字体大小**：24pt
- **字体颜色**：白色
- **背景**：半透明黑色 (30% 透明度)
- **圆角**：8pt
- **内边距**：20pt
- **透明度**：80%

### 自定义样式示例

```swift
// 创建自定义水印配置
let customConfig = WatermarkConfig(
    text: "Custom Watermark",
    fontSize: 32.0,
    fontColor: .systemBlue,
    backgroundColor: NSColor.white.withAlphaComponent(0.2),
    position: .center,
    opacity: 0.9,
    padding: 30.0
)

// 应用配置
daemon.updateWatermarkConfig(customConfig)
```

## 性能考虑

### 优化建议
1. **文字长度**：避免过长的文字，建议不超过20个字符
2. **字体大小**：根据屏幕分辨率调整，避免过大或过小
3. **透明度**：适中的透明度（0.6-0.9）效果最佳
4. **位置选择**：避免遮挡重要内容

### 多屏幕支持
- 水印会在所有连接的屏幕上显示
- 每个屏幕的水印位置和样式保持一致
- 支持动态添加/移除屏幕

## 故障排除

### 常见问题

1. **水印不显示**
   - 检查 `show_watermark` 参数是否为 `true`
   - 确认文字内容不为空

2. **位置不正确**
   - 检查位置参数拼写是否正确
   - 确认使用小写字母（如 `bottomright`）

3. **文字模糊**
   - 检查屏幕缩放设置
   - 确认 `contentsScale` 设置正确

4. **性能问题**
   - 减少文字长度
   - 降低透明度
   - 使用更简单的背景样式

## 更新日志

### v1.0.0
- 初始水印功能
- 支持5个位置
- 可自定义文字和透明度
- 多屏幕支持

### 计划功能
- 图片水印支持
- 动画水印效果
- 更多字体选项
- 水印预设模板 