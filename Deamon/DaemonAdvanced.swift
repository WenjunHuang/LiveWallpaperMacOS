/*
 * This file is part of LiveWallpaper – LiveWallpaper App for macOS.
 * Copyright (C) 2025 Bios thusvill
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import AVFoundation
import Cocoa
import QuartzCore

// MARK: - 错误类型定义
enum WallpaperError: Error, LocalizedError {
    case videoFileNotFound
    case videoLoadFailed
    case frameGenerationFailed
    case windowCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .videoFileNotFound:
            return "Video file not found"
        case .videoLoadFailed:
            return "Failed to load video"
        case .frameGenerationFailed:
            return "Failed to generate static frame"
        case .windowCreationFailed:
            return "Failed to create wallpaper window"
        }
    }
}

// MARK: - 屏幕信息结构
struct ScreenInfo {
    let screen: NSScreen
    let window: NSWindow
    let player: AVQueuePlayer
    let layer: AVPlayerLayer
    let looper: AVPlayerLooper
}

// MARK: - 水印配置结构体
struct WatermarkConfig {
    let text: String
    let fontSize: CGFloat
    let fontColor: NSColor
    let backgroundColor: NSColor?
    let position: WatermarkPosition
    let opacity: CGFloat
    let padding: CGFloat
    
    enum WatermarkPosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    static let `default` = WatermarkConfig(
        text: "LiveWallpaper",
        fontSize: 24.0,
        fontColor: .white,
        backgroundColor: NSColor.black.withAlphaComponent(0.3),
        position: .bottomRight,
        opacity: 0.8,
        padding: 20.0
    )
}

class WatermarkView: NSView {
    private let config: WatermarkConfig
    private let textLayer = CATextLayer()
    private let backgroundLayer = CALayer()
    
    init(config: WatermarkConfig) {
        self.config = config
        super.init(frame: .zero)
        setupWatermark()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWatermark() {
        // 设置背景层
        backgroundLayer.backgroundColor = config.backgroundColor?.cgColor
        backgroundLayer.cornerRadius = 8.0
        backgroundLayer.opacity = Float(config.opacity)
        layer?.addSublayer(backgroundLayer)
        
        // 设置文字层
        textLayer.string = config.text
        textLayer.font = NSFont.systemFont(ofSize: config.fontSize, weight: .medium)
        textLayer.fontSize = config.fontSize
        textLayer.foregroundColor = config.fontColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        textLayer.opacity = Float(config.opacity)
        layer?.addSublayer(textLayer)
        
        // 设置视图属性
        wantsLayer = true
        layer?.masksToBounds = false
    }
    
    override func layout() {
        super.layout()
        updateWatermarkLayout()
    }
    
    private func updateWatermarkLayout() {
        let bounds = self.bounds
        
        // 计算文字大小
        let textSize = (config.text as NSString).size(
            withAttributes: [
                .font: NSFont.systemFont(ofSize: config.fontSize, weight: .medium)
            ]
        )
        
        let watermarkWidth = textSize.width + config.padding * 2
        let watermarkHeight = textSize.height + config.padding * 2
        
        // 根据位置计算坐标
        let (x, y) = calculatePosition(
            watermarkWidth: watermarkWidth,
            watermarkHeight: watermarkHeight,
            containerBounds: bounds
        )
        
        // 更新背景层
        backgroundLayer.frame = CGRect(
            x: x,
            y: y,
            width: watermarkWidth,
            height: watermarkHeight
        )
        
        // 更新文字层
        textLayer.frame = CGRect(
            x: x + config.padding,
            y: y + config.padding,
            width: textSize.width,
            height: textSize.height
        )
    }
    
    private func calculatePosition(
        watermarkWidth: CGFloat,
        watermarkHeight: CGFloat,
        containerBounds: CGRect
    ) -> (CGFloat, CGFloat) {
        let containerWidth = containerBounds.width
        let containerHeight = containerBounds.height
        
        switch config.position {
        case .topLeft:
            return (config.padding, containerHeight - watermarkHeight - config.padding)
        case .topRight:
            return (containerWidth - watermarkWidth - config.padding, containerHeight - watermarkHeight - config.padding)
        case .bottomLeft:
            return (config.padding, config.padding)
        case .bottomRight:
            return (containerWidth - watermarkWidth - config.padding, config.padding)
        case .center:
            return (
                (containerWidth - watermarkWidth) / 2,
                (containerHeight - watermarkHeight) / 2
            )
        }
    }
    
    func updateText(_ newText: String) {
        config.text = newText
        textLayer.string = newText
        updateWatermarkLayout()
    }
    
    func updateOpacity(_ opacity: CGFloat) {
        textLayer.opacity = Float(opacity)
        backgroundLayer.opacity = Float(opacity)
    }
}

// MARK: - 主守护进程类
class VideoWallpaperDaemon: NSObject {
    private var screenInfos: [ScreenInfo] = []
    private var isScreenLocked = false
    
    // 配置选项
    private let videoPath: String
    private let frameOutputPath: String?
    private let enableAudio: Bool
    private let volume: Float
    
    // 水印配置
    private var watermarkConfig: WatermarkConfig
    private var showWatermark: Bool
    
    init(videoPath: String, frameOutput: String?, enableAudio: Bool = false, volume: Float = 0.0, watermarkConfig: WatermarkConfig? = nil, showWatermark: Bool = true) throws {
        self.videoPath = videoPath
        self.frameOutputPath = frameOutput
        self.enableAudio = enableAudio
        self.volume = volume
        self.watermarkConfig = watermarkConfig ?? WatermarkConfig.default
        self.showWatermark = showWatermark
        
        super.init()
        
        // 验证视频文件
        guard FileManager.default.fileExists(atPath: videoPath) else {
            throw WallpaperError.videoFileNotFound
        }
        
        // 初始化
        try setup()
    }
    
    private func setup() throws {
        // 生成静态帧
        if let framePath = frameOutputPath {
            try generateStaticFrame(from: videoPath, outputPath: framePath)
        }
        
        // 设置通知监听
        setupNotifications()
        
        // 创建动态壁纸
        try createWallpaperWindows()
        
        print("✅ VideoWallpaperDaemon initialized successfully")
    }
    
    private func generateStaticFrame(from videoPath: String, outputPath: String) throws {
        let videoURL = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: videoURL)
        
        // 检查视频是否可播放
        let playableKey = "playable"
        let status = try await asset.load(.isPlayable)
        guard status else {
            throw WallpaperError.videoLoadFailed
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 1920, height: 1080)
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            
            guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
                throw WallpaperError.frameGenerationFailed
            }
            
            try data.write(to: URL(fileURLWithPath: outputPath))
            print("✅ Static frame generated: \(outputPath)")
            
        } catch {
            print("❌ Frame generation failed: \(error.localizedDescription)")
            throw WallpaperError.frameGenerationFailed
        }
    }
    
    private func setupNotifications() {
        let center = DistributedNotificationCenter.default()
        
        center.addObserver(
            self,
            selector: #selector(screenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(screenUnlocked),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        
        // 监听应用程序激活/停用
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }
    
    private func createWallpaperWindows() throws {
        let screens = NSScreen.screens
        let videoURL = URL(fileURLWithPath: videoPath)
        
        for screen in screens {
            let screenInfo = try createWallpaperWindow(for: screen, videoURL: videoURL)
            screenInfos.append(screenInfo)
        }
        
        print("✅ Created \(screenInfos.count) wallpaper windows")
    }
    
    private func createWallpaperWindow(for screen: NSScreen, videoURL: URL) throws -> ScreenInfo {
        let frame = screen.frame
        
        // 创建无边框窗口
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        // 配置窗口属性
        window.level = .desktopIcon - 1
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.hasShadow = false
        window.toggleFullScreen(nil)
        
        // 创建视频播放器
        let asset = AVAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer()
        let looper = AVPlayerLooper(player: player, templateItem: item)
        
        // 配置播放器
        player.volume = enableAudio ? volume : 0.0
        player.isMuted = !enableAudio
        
        // 设置视频层
        window.contentView?.wantsLayer = true
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = window.contentView?.bounds ?? .zero
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.needsDisplayOnBoundsChange = true
        layer.actions = ["contents": NSNull()]
        
        window.contentView?.layer?.addSublayer(layer)
        
        // 添加水印视图
        if showWatermark {
            let watermarkView = WatermarkView(config: watermarkConfig)
            watermarkView.frame = window.contentView?.bounds ?? .zero
            watermarkView.autoresizingMask = [.width, .height]
            window.contentView?.addSubview(watermarkView)
        }
        
        // 设置窗口位置
        window.setFrameOrigin(frame.origin)
        
        // 禁用动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.commit()
        
        window.makeKeyAndOrderFront(nil)
        
        // 开始播放
        player.play()
        
        return ScreenInfo(
            screen: screen,
            window: window,
            player: player,
            layer: layer,
            looper: looper
        )
    }
    
    // MARK: - 通知处理方法
    @objc private func screenLocked(_ notification: Notification) {
        isScreenLocked = true
        pauseAllPlayers()
        print("🔒 Screen locked - paused all players")
    }
    
    @objc private func screenUnlocked(_ notification: Notification) {
        isScreenLocked = false
        resumeAllPlayers()
        print("🔓 Screen unlocked - resumed all players")
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        if !isScreenLocked {
            resumeAllPlayers()
        }
    }
    
    @objc private func applicationDidResignActive(_ notification: Notification) {
        pauseAllPlayers()
    }
    
    // MARK: - 播放控制方法
    private func pauseAllPlayers() {
        for screenInfo in screenInfos {
            screenInfo.player.pause()
        }
    }
    
    private func resumeAllPlayers() {
        for screenInfo in screenInfos {
            screenInfo.player.play()
        }
    }
    
    // MARK: - 公共方法
    func setVolume(_ volume: Float) {
        for screenInfo in screenInfos {
            screenInfo.player.volume = volume
        }
    }
    
    func toggleMute() {
        for screenInfo in screenInfos {
            screenInfo.player.isMuted.toggle()
        }
    }
    
    func restart() {
        for screenInfo in screenInfos {
            screenInfo.player.seek(to: .zero)
            screenInfo.player.play()
        }
    }
    
    func cleanup() {
        // 移除通知监听
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        
        // 停止所有播放器
        for screenInfo in screenInfos {
            screenInfo.player.pause()
            screenInfo.window.close()
        }
        
        screenInfos.removeAll()
        print("🧹 Cleanup completed")
    }
    
    // MARK: - 水印控制方法
    
    func updateWatermarkText(_ text: String) {
        for screenInfo in screenInfos {
            let window = screenInfo.window
            if let layer = window.contentView?.layer as? AVPlayerLayer {
                if let watermarkView = layer.sublayers?.first(where: { $0 is WatermarkView }) as? WatermarkView {
                    watermarkView.updateText(text)
                }
            }
        }
    }
    
    func updateWatermarkOpacity(_ opacity: CGFloat) {
        for screenInfo in screenInfos {
            let window = screenInfo.window
            if let layer = window.contentView?.layer as? AVPlayerLayer {
                if let watermarkView = layer.sublayers?.first(where: { $0 is WatermarkView }) as? WatermarkView {
                    watermarkView.updateOpacity(opacity)
                }
            }
        }
    }
    
    func showWatermark(_ show: Bool) {
        for screenInfo in screenInfos {
            let window = screenInfo.window
            if let layer = window.contentView?.layer as? AVPlayerLayer {
                if let watermarkView = layer.sublayers?.first(where: { $0 is WatermarkView }) as? WatermarkView {
                    watermarkView.isHidden = !show
                }
            }
        }
    }
    
    func updateWatermarkConfig(_ config: WatermarkConfig) {
        watermarkConfig = config
        // 重新创建水印视图
        for screenInfo in screenInfos {
            let window = screenInfo.window
            if let layer = window.contentView?.layer as? AVPlayerLayer {
                if let watermarkView = layer.sublayers?.first(where: { $0 is WatermarkView }) as? WatermarkView {
                    watermarkView.removeFromSuperview()
                }
                
                if showWatermark {
                    let newWatermarkView = WatermarkView(config: config)
                    newWatermarkView.frame = window.contentView?.bounds ?? .zero
                    newWatermarkView.autoresizingMask = [.width, .height]
                    window.contentView?.addSubview(newWatermarkView)
                }
            }
        }
    }
}

// MARK: - 主程序入口
@main
struct WallpaperDaemon {
    static func main() {
        let args = CommandLine.arguments
        
        guard args.count >= 3 else {
            print("Usage: \(args[0]) <video.mp4> <frame_output.png> [enable_audio] [volume] [watermark_text] [watermark_position] [show_watermark]")
            print("Positions: topLeft, topRight, bottomLeft, bottomRight, center")
            print("Example: \(args[0]) video.mp4 frame.png false 0.0 \"My Watermark\" bottomRight true")
            exit(1)
        }
        
        let videoPath = args[1]
        let framePath = args[2]
        let enableAudio = args.count > 3 ? (args[3] == "true") : false
        let volume = args.count > 4 ? Float(args[4]) ?? 0.0 : 0.0
        
        // 解析水印参数
        var watermarkText = "LiveWallpaper"
        var watermarkPosition = WatermarkConfig.WatermarkPosition.bottomRight
        var showWatermark = true
        
        if args.count > 5 {
            watermarkText = args[5]
        }
        
        if args.count > 6 {
            switch args[6].lowercased() {
            case "topleft":
                watermarkPosition = .topLeft
            case "topright":
                watermarkPosition = .topRight
            case "bottomleft":
                watermarkPosition = .bottomLeft
            case "bottomright":
                watermarkPosition = .bottomRight
            case "center":
                watermarkPosition = .center
            default:
                watermarkPosition = .bottomRight
            }
        }
        
        if args.count > 7 {
            showWatermark = args[7].lowercased() == "true"
        }
        
        // 创建水印配置
        var config = WatermarkConfig.default
        config.text = watermarkText
        config.position = watermarkPosition
        
        do {
            let daemon = try VideoWallpaperDaemon(
                videoPath: videoPath,
                frameOutput: framePath,
                enableAudio: enableAudio,
                volume: volume,
                watermarkConfig: config,
                showWatermark: showWatermark
            )
            
            // 设置信号处理
            signal(SIGINT) { _ in
                print("\n🛑 Received interrupt signal, cleaning up...")
                daemon.cleanup()
                exit(0)
            }
            
            signal(SIGTERM) { _ in
                print("\n🛑 Received termination signal, cleaning up...")
                daemon.cleanup()
                exit(0)
            }
            
            print("🎬 VideoWallpaperDaemon started successfully")
            print("📺 Video: \(videoPath)")
            print("🔊 Audio: \(enableAudio ? "enabled" : "disabled")")
            print("📱 Screens: \(NSScreen.screens.count)")
            print("💧 Watermark: '\(watermarkText)' at \(watermarkPosition)")
            
            // 运行主循环
            RunLoop.main.run()
            
        } catch {
            print("❌ Failed to start VideoWallpaperDaemon: \(error.localizedDescription)")
            exit(1)
        }
    }
} 