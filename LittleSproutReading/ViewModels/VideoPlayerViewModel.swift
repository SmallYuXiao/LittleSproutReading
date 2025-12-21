//
//  VideoPlayerViewModel.swift
//  LittleSproutReading
//
//  视频播放器ViewModel
//

import Foundation
import AVFoundation
import Combine

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var subtitles: [Subtitle] = []
    @Published var currentSubtitleIndex: Int? = nil
    @Published var subtitleOffset: Double = 0.0  // 字幕偏移量(秒)
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    /// 加载视频和字幕
    func loadVideo(_ video: Video) {
        // 调试信息
        print("🎬 尝试加载视频: \(video.fileName)")
        print("📁 Bundle路径: \(Bundle.main.resourcePath ?? "未知")")
        print("📁 Bundle URL: \(Bundle.main.bundleURL)")
        
        // 检查视频文件
        if let videoURL = video.videoURL {
            print("✅ 视频URL: \(videoURL.path)")
            print("📹 文件存在: \(FileManager.default.fileExists(atPath: videoURL.path))")
        } else {
            print("❌ 视频文件不存在: \(video.fileName)")
        }
        
        // 检查字幕文件
        if let subtitleURL = video.subtitleURL {
            print("✅ 字幕URL: \(subtitleURL.path)")
            print("📝 文件存在: \(FileManager.default.fileExists(atPath: subtitleURL.path))")
        } else {
            print("❌ 字幕文件不存在: \(video.subtitleFileName)")
        }
        
        // 加载视频
        guard let videoURL = video.videoURL else {
            print("❌ 无法加载视频,URL为空")
            return
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        
        // 监听播放时间
        setupTimeObserver()
        
        // 获取视频时长
        playerItem.publisher(for: \.duration)
            .sink { [weak self] duration in
                let seconds = duration.seconds
                // 确保duration是有效数字
                if seconds.isFinite && seconds > 0 {
                    self?.duration = seconds
                } else {
                    self?.duration = 0
                }
            }
            .store(in: &cancellables)
        
        // 加载字幕
        loadSubtitles(video)
    }
    
    /// 加载字幕文件
    private func loadSubtitles(_ video: Video) {
        guard let subtitleURL = video.subtitleURL else {
            print("❌ 字幕文件不存在: \(video.subtitleFileName)")
            return
        }
        
        subtitles = SubtitleParser.parseSRT(from: subtitleURL)
        print("✅ 加载了 \(subtitles.count) 条字幕")
    }
    
    /// 设置时间监听器(每0.1秒更新一次)
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            self?.updateCurrentSubtitle()
        }
    }
    
    /// 更新当前字幕(应用偏移量)
    private func updateCurrentSubtitle() {
        let adjustedTime = currentTime + subtitleOffset
        currentSubtitleIndex = subtitles.firstIndex { $0.contains(time: adjustedTime) }
    }
    
    /// 调整字幕偏移量
    func adjustSubtitleOffset(by delta: Double) {
        subtitleOffset += delta
        updateCurrentSubtitle()
        print("📊 字幕偏移: \(String(format: "%.1f", subtitleOffset))秒")
    }
    
    /// 播放/暂停
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    /// 跳转到指定时间
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    /// 跳转到指定字幕
    func seekToSubtitle(_ subtitle: Subtitle) {
        seek(to: subtitle.startTime)
        if !isPlaying {
            togglePlayPause()
        }
    }
    
    /// 格式化时间显示
    func formatTime(_ seconds: Double) -> String {
        // 安全检查:确保是有效数字
        guard seconds.isFinite else {
            return "00:00"
        }
        
        let safeSeconds = max(0, seconds)  // 确保非负
        let minutes = Int(safeSeconds) / 60
        let secs = Int(safeSeconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
