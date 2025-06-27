@echo off
REM LiveWallpaper 水印功能测试脚本 (Windows版本)
REM 使用方法: test_watermark.bat <video_path>

if "%~1"=="" (
    echo 使用方法: %0 ^<video_path^>
    echo 示例: %0 C:\path\to\video.mp4
    pause
    exit /b 1
)

set VIDEO_PATH=%~1
set FRAME_PATH=%TEMP%\test_frame.png

REM 检查视频文件是否存在
if not exist "%VIDEO_PATH%" (
    echo ❌ 错误: 视频文件不存在: %VIDEO_PATH%
    pause
    exit /b 1
)

echo 🎬 LiveWallpaper 水印功能测试
echo 📹 视频文件: %VIDEO_PATH%
echo.

echo 🧪 开始测试不同的水印配置...
echo.

REM 1. 默认水印（右下角）
echo 1️⃣ 测试默认水印（右下角显示'LiveWallpaper'）
echo    命令: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%"
echo    预期: 右下角显示 'LiveWallpaper'
echo.

REM 2. 自定义文字水印
echo 2️⃣ 测试自定义文字水印
echo    命令: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "My Company"
echo    预期: 右下角显示 'My Company'
echo.

REM 3. 不同位置的水印
echo 3️⃣ 测试不同位置的水印
echo    左上角: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "Top Left" topLeft
echo    右上角: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "Top Right" topRight
echo    左下角: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "Bottom Left" bottomLeft
echo    中央: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "Center" center
echo.

REM 4. 版权信息示例
echo 4️⃣ 测试版权信息水印
echo    命令: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "© 2025 My Company" bottomLeft
echo    预期: 左下角显示版权信息
echo.

REM 5. 品牌标识示例
echo 5️⃣ 测试品牌标识水印
echo    命令: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "BRAND" topRight
echo    预期: 右上角显示品牌标识
echo.

REM 6. 禁用水印
echo 6️⃣ 测试禁用水印
echo    命令: wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%" false 0.0 "No Watermark" bottomRight false
echo    预期: 不显示任何水印
echo.

echo 📋 测试说明:
echo    - 每个测试会启动一个新的守护进程
echo    - 使用 Ctrl+C 停止当前测试
echo    - 观察水印的位置、样式和内容
echo    - 检查多屏幕支持（如果有多个显示器）
echo.

echo 🚀 开始第一个测试（默认水印）...
echo 按任意键开始，或关闭窗口退出
pause >nul

REM 启动第一个测试
echo 🎬 启动默认水印测试...
wallpaperdeamon.exe "%VIDEO_PATH%" "%FRAME_PATH%"

echo.
echo ✅ 测试完成！
echo 💡 提示: 可以修改此脚本来自动化测试不同的水印配置
pause 