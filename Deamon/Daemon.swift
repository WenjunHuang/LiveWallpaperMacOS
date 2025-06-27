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

class VideoWallpaperDaemon: NSObject {
    private var windows: [NSWindow] = []
    private var players: [AVQueuePlayer] = []
    private var playerLayers: [AVPlayerLayer] = []
    private var loopers: [AVPlayerLooper] = []
    
    init(videoPath: String, frameOutput: String?) {
        super.init()
        
        // 生成静态帧作为备用壁纸
        if let framePath = frameOutput {
            generateStaticFrame(from: videoPath, outputPath: framePath)
        }
        
        // 监听屏幕锁定/解锁事件
        setupScreenLockNotifications()
        
        // 设置动态壁纸
        setupWallpaper(with: videoPath)
    }
    
    private func generateStaticFrame(from videoPath: String, outputPath: String) {
        let videoURL = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] requestedTime, cgImage, actualTime, result, error in
            if result == .succeeded, let cgImage = cgImage {
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                if let data = bitmapRep.representation(using: .png, properties: [:]) {
                    try? data.write(to: URL(fileURLWithPath: outputPath))
                }
            } else if let error = error {
                print("Frame extraction failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupScreenLockNotifications() {
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
    }
    
    private func setupWallpaper(with videoPath: String) {
        let screens = NSScreen.screens
        let videoURL = URL(fileURLWithPath: videoPath)
        
        for screen in screens {
            let frame = screen.frame
            
            // 创建无边框窗口
            let window = NSWindow(
                contentRect: frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            
            // 设置窗口属性
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
            
            // 设置视频层
            window.contentView?.wantsLayer = true
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            layer.frame = window.contentView?.bounds ?? .zero
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.needsDisplayOnBoundsChange = true
            layer.actions = ["contents": NSNull()]
            
            window.contentView?.layer?.addSublayer(layer)
            
            // 设置窗口位置
            window.setFrameOrigin(frame.origin)
            
            print("Screen frame: \(screen.frame)")
            print("ContentView bounds: \(window.contentView?.bounds ?? .zero)")
            
            // 禁用动画
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.commit()
            
            window.makeKeyAndOrderFront(nil)
            
            // 静音播放
            player.volume = 0.0
            player.isMuted = true
            
            // 保存引用
            windows.append(window)
            players.append(player)
            playerLayers.append(layer)
            loopers.append(looper)
            
            // 开始播放
            player.play()
        }
    }
    
    @objc private func screenLocked(_ notification: Notification) {
        for player in players {
            player.pause()
        }
    }
    
    @objc private func screenUnlocked(_ notification: Notification) {
        for player in players {
            player.play()
        }
    }
}

// 主函数
@main
struct WallpaperDaemon {
    static func main() {
        let args = CommandLine.arguments
        
        guard args.count >= 3 else {
            print("Usage: \(args[0]) <video.mp4> <frame_output.png>")
            exit(1)
        }
        
        let videoPath = args[1]
        let framePath = args[2]
        
        let daemon = VideoWallpaperDaemon(videoPath: videoPath, frameOutput: framePath)
        
        // 运行主循环
        RunLoop.main.run()
    }
} 