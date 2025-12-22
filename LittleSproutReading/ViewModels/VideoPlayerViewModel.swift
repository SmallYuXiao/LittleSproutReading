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
    
    // YouTube 相关
    @Published var currentVideo: Video?
    @Published var videoTitle: String?  // 从 API 获取的视频标题
    @Published var videoFormats: [VideoFormat] = []  // 可用的视频格式
    @Published var selectedFormat: VideoFormat?      // 当前选择的格式
    @Published var isLoadingSubtitles = false
    @Published var subtitleError: String?
    @Published var isVideoReady = false  // 视频是否就绪
    
    // 历史记录
    let historyManager = HistoryManager()
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    
    /// 加载视频
    func loadVideo(_ video: Video) {
        currentVideo = video
        
        // 只处理 YouTube 视频
        loadYouTubeSubtitles(video)
    }
    
    
    /// 加载 YouTube 字幕（使用 iiiLab/snapany API）
    private func loadYouTubeSubtitles(_ video: Video) {
        let videoID = video.youtubeVideoID
        
        isLoadingSubtitles = true
        subtitleError = nil
        
        Task {
            do {
                // 使用 iiiLab 服务获取完整的视频信息（包括字幕）
                let videoInfo = try await YouTubeSubtitleService.shared
                    .fetchVideoInfoWithSubtitles(videoID: videoID)
                
                // 更新视频标题和格式信息
                await MainActor.run {
                    if let title = videoInfo.title {
                        self.videoTitle = title
                        print("📺 视频标题: \(title)")
                    }
                    
                    // 保存视频格式信息
                    self.videoFormats = videoInfo.formats ?? []
                    print("🎬 获取了 \(self.videoFormats.count) 种视频格式")
                    
                    // 自动选择最佳格式
                    self.selectedFormat = self.selectBestFormat(from: self.videoFormats)
                    
                    // 如果有选中的格式，加载视频
                    if let format = self.selectedFormat {
                        print("✅ 选择格式: \(format.quality) (\(format.format))")
                        self.loadVideoFromURL(format.video_url)
                    }
                }
                
                // 查找英文和中文字幕
                var englishSubtitle: VideoSubtitle?
                var chineseSubtitle: VideoSubtitle?
                
                if let subtitles = videoInfo.subtitles {
                    // 查找英文字幕
                    englishSubtitle = subtitles.first(where: {
                        $0.language.lowercased().contains("en") ||
                        $0.language_name.lowercased().contains("english")
                    })
                    
                    // 查找中文字幕
                    chineseSubtitle = subtitles.first(where: {
                        $0.language.lowercased().contains("zh") ||
                        $0.language_name.lowercased().contains("chinese") ||
                        $0.language_name.contains("中文")
                    })
                    
                    print("📝 找到字幕: 英文=\(englishSubtitle != nil), 中文=\(chineseSubtitle != nil)")
                }
                
                // 下载字幕
                var englishSubs: [Subtitle] = []
                var chineseSubs: [Subtitle] = []
                
                if let english = englishSubtitle {
                    print("⬇️ 下载英文字幕: \(english.language_name)")
                    englishSubs = try await YouTubeSubtitleService.shared
                        .downloadSubtitleContent(from: english.url)
                }
                
                if let chinese = chineseSubtitle {
                    print("⬇️ 下载中文字幕: \(chinese.language_name)")
                    chineseSubs = try await YouTubeSubtitleService.shared
                        .downloadSubtitleContent(from: chinese.url)
                }
                
                // 合并字幕
                let mergedSubtitles = self.mergeSubtitles(english: englishSubs, chinese: chineseSubs)
                
                await MainActor.run {
                    self.subtitles = mergedSubtitles
                    print("✅ 加载了 \(mergedSubtitles.count) 条双语字幕")
                    self.isLoadingSubtitles = false
                    
                    // 保存到历史记录
                    if let title = self.videoTitle, let video = self.currentVideo {
                        let history = VideoHistory(
                            videoID: video.youtubeVideoID,
                            title: title
                        )
                        self.historyManager.addHistory(history)
                    }
                }
                
                if mergedSubtitles.isEmpty {
                    throw YouTubeSubtitleError.noSubtitles
                }
                
            } catch {
                await MainActor.run {
                    self.subtitleError = "字幕加载失败: \(error.localizedDescription)"
                    self.isLoadingSubtitles = false
                    print("❌ 字幕加载失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 合并英文和中文字幕
    private func mergeSubtitles(english: [Subtitle], chinese: [Subtitle]) -> [Subtitle] {
        // 如果只有一种字幕，直接返回
        if english.isEmpty && !chinese.isEmpty {
            return chinese
        }
        if chinese.isEmpty && !english.isEmpty {
            return english
        }
        if english.isEmpty && chinese.isEmpty {
            return []
        }
        
        // 合并双语字幕
        var merged: [Subtitle] = []
        
        for (index, englishSub) in english.enumerated() {
            // 查找时间最接近的中文字幕（容差 0.5 秒）
            let chineseText = chinese.first(where: {
                abs($0.startTime - englishSub.startTime) < 0.5
            })?.chineseText ?? ""
            
            let subtitle = Subtitle(
                index: index + 1,
                startTime: englishSub.startTime,
                endTime: englishSub.endTime,
                englishText: englishSub.englishText,
                chineseText: chineseText
            )
            merged.append(subtitle)
        }
        
        return merged
    }
    
    /// 从可用格式中选择最佳格式
    private func selectBestFormat(from formats: [VideoFormat]) -> VideoFormat? {
        // 优先选择不分离的格式（音视频在一起），因为 AVPlayer 无法直接播放分离的流
        let notSeparateFormats = formats.filter { !$0.separate }
        
        if !notSeparateFormats.isEmpty {
            // 在不分离的格式中，选择质量最高的
            let sorted = notSeparateFormats.sorted { $0.quality_value > $1.quality_value }
            print("📺 选择不分离的格式: \(sorted.first?.quality ?? "unknown")")
            return sorted.first
        }
        
        // 如果没有不分离的格式，暂时返回 nil
        // TODO: 未来可以实现音视频合并功能
        print("⚠️ 所有格式都是音视频分离的，AVPlayer 无法直接播放")
        return nil
    }
    
    /// 从 URL 加载视频
    func loadVideoFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ 无效的视频 URL")
            subtitleError = "无效的视频 URL"
            return
        }
        
        print("🎬 加载视频 URL: \(urlString.prefix(100))...")
        
        // 重置视频就绪状态
        isVideoReady = false
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // 设置时间监听器
        setupTimeObserver()
        
        // 监听 playerItem 的 status 变化
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    print("✅ 视频就绪，可以播放")
                    self?.isVideoReady = true
                case .failed:
                    print("❌ 视频加载失败: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    self?.isVideoReady = false
                    self?.subtitleError = "视频加载失败"
                case .unknown:
                    print("⏳ 视频状态: 未知")
                    self?.isVideoReady = false
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // 获取视频时长
        playerItem.publisher(for: \.duration)
            .sink { [weak self] duration in
                let seconds = duration.seconds
                if seconds.isFinite && seconds > 0 {
                    self?.duration = seconds
                    print("⏱️ 视频时长: \(Int(seconds))秒")
                }
            }
            .store(in: &cancellables)
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
