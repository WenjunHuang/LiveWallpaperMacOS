#!/bin/bash

# LiveWallpaper 水印功能测试脚本
# 使用方法: ./test_watermark.sh <video_path>

if [ $# -eq 0 ]; then
    echo "使用方法: $0 <video_path>"
    echo "示例: $0 /path/to/video.mp4"
    exit 1
fi

VIDEO_PATH="$1"
FRAME_PATH="/tmp/test_frame.png"

# 检查视频文件是否存在
if [ ! -f "$VIDEO_PATH" ]; then
    echo "❌ 错误: 视频文件不存在: $VIDEO_PATH"
    exit 1
fi

echo "🎬 LiveWallpaper 水印功能测试"
echo "📹 视频文件: $VIDEO_PATH"
echo ""

# 测试不同的水印配置
echo "🧪 开始测试不同的水印配置..."
echo ""

# 1. 默认水印（右下角）
echo "1️⃣ 测试默认水印（右下角显示'LiveWallpaper'）"
echo "   命令: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\""
echo "   预期: 右下角显示 'LiveWallpaper'"
echo ""

# 2. 自定义文字水印
echo "2️⃣ 测试自定义文字水印"
echo "   命令: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"My Company\""
echo "   预期: 右下角显示 'My Company'"
echo ""

# 3. 不同位置的水印
echo "3️⃣ 测试不同位置的水印"
echo "   左上角: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"Top Left\" topLeft"
echo "   右上角: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"Top Right\" topRight"
echo "   左下角: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"Bottom Left\" bottomLeft"
echo "   中央: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"Center\" center"
echo ""

# 4. 版权信息示例
echo "4️⃣ 测试版权信息水印"
echo "   命令: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"© 2025 My Company\" bottomLeft"
echo "   预期: 左下角显示版权信息"
echo ""

# 5. 品牌标识示例
echo "5️⃣ 测试品牌标识水印"
echo "   命令: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"BRAND\" topRight"
echo "   预期: 右上角显示品牌标识"
echo ""

# 6. 禁用水印
echo "6️⃣ 测试禁用水印"
echo "   命令: ./wallpaperdeamon \"$VIDEO_PATH\" \"$FRAME_PATH\" false 0.0 \"No Watermark\" bottomRight false"
echo "   预期: 不显示任何水印"
echo ""

echo "📋 测试说明:"
echo "   - 每个测试会启动一个新的守护进程"
echo "   - 使用 Ctrl+C 停止当前测试"
echo "   - 观察水印的位置、样式和内容"
echo "   - 检查多屏幕支持（如果有多个显示器）"
echo ""

echo "🚀 开始第一个测试（默认水印）..."
echo "按 Enter 键开始，或 Ctrl+C 退出"
read -r

# 启动第一个测试
echo "🎬 启动默认水印测试..."
./wallpaperdeamon "$VIDEO_PATH" "$FRAME_PATH"

echo ""
echo "✅ 测试完成！"
echo "💡 提示: 可以修改此脚本来自动化测试不同的水印配置" 