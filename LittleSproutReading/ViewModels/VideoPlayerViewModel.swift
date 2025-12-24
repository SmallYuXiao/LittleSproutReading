//
//  VideoPlayerViewModel.swift
//  LittleSproutReading
//
//  视频播放器ViewModel
//

import Foundation
import AVFoundation
import Combine

class VideoPlayerViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var subtitles: [Subtitle] = []
    @Published var currentSubtitleIndex: Int? = nil
    @Published var subtitleOffset: Double = 0.0  // 字幕偏移量(秒)
    
    // 街溜子模式 (中英轮读)
    @Published var isStreetWandererMode = false
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenIndex: Int? = nil
    
    // YouTube 相关
    @Published var currentVideo: Video?
    @Published var videoTitle: String?  // 从 API 获取的视频标题
    @Published var videoFormats: [VideoFormat] = []  // 可用的视频格式
    @Published var selectedFormat: VideoFormat?      // 当前选择的格式
    @Published var isLoadingSubtitles = false
    @Published var subtitleError: String?
    @Published var isVideoReady = false  // 视频是否就绪
    @Published var originalInputURL: String = ""  // 用户输入的原始 URL
    
    // 历史记录
    let historyManager = HistoryManager()
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// 加载视频
    func loadVideo(_ video: Video, originalURL: String = "") {
        
        // 重置状态
        lastSpokenIndex = nil
        synthesizer.stopSpeaking(at: .immediate)
        
        // 设置当前视频 - 这会触发 UI 更新
        currentVideo = video
        
        originalInputURL = originalURL.isEmpty ? "https://www.youtube.com/watch?v=\(video.youtubeVideoID)" : originalURL
        
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
                    }
                    
                    // 保存视频格式信息
                    self.videoFormats = videoInfo.formats ?? []
                    
                    // 打印所有可用格式
                    for (index, format) in self.videoFormats.enumerated() {
                    }
                    
                    // 自动选择最佳格式
                    self.selectedFormat = self.selectBestFormat(from: self.videoFormats)
                    
                    // 如果有选中的格式，加载视频
                    if let format = self.selectedFormat {
                        self.loadVideoFromURL(format.video_url)
                    } else {
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
                    
                }
                
                
                // 下载字幕
                var englishSubs: [Subtitle] = []
                var chineseSubs: [Subtitle] = []
                
                if let english = englishSubtitle {
                    englishSubs = try await YouTubeSubtitleService.shared
                        .downloadSubtitleContent(from: english.url)
                }
                
                if let chinese = chineseSubtitle {
                    chineseSubs = try await YouTubeSubtitleService.shared
                        .downloadSubtitleContent(from: chinese.url)
                } else {
                    // 四级回退逻辑
                    
                    // 1. 尝试使用后端翻译接口 (youtube-transcript-api)
                    do {
                        chineseSubs = try await YouTubeSubtitleService.shared
                            .fetchSubtitles(videoID: videoID, language: "zh")
                    } catch {
                        
                        // 2. 尝试使用时间戳API (新增备选方案)
                        do {
                            chineseSubs = try await YouTubeSubtitleService.shared
                                .fetchSubtitlesWithTimestamps(videoID: videoID, languages: ["zh", "zh-Hans"])
                        } catch {
                            
                            // 3. 尝试 Smart URL 翻译 (利用 iiilab 提供的 YouTube 直接链接)
                            if let english = englishSubtitle, english.url.contains("youtube.com/api/timedtext") {
                                let translatedURL = english.url + "&tlang=zh-Hans"
                                do {
                                    chineseSubs = try await YouTubeSubtitleService.shared
                                        .downloadSubtitleContent(from: translatedURL)
                                } catch {
                                }
                            }
                        }
                    }
                }
                
                // 合并字幕
                let mergedSubtitles = self.mergeSubtitles(english: englishSubs, chinese: chineseSubs)
                
                
                await MainActor.run {
                    self.subtitles = mergedSubtitles
                    self.isLoadingSubtitles = false
                    
                    // 如果没有字幕,显示提示但不阻止播放
                    if mergedSubtitles.isEmpty {
                        self.subtitleError = "该视频暂无字幕,但您仍可以观看视频"
                    }
                    
                    // 保存到历史记录
                    if let title = self.videoTitle, let video = self.currentVideo {
                        let history = VideoHistory(
                            videoID: video.youtubeVideoID,
                            title: title,
                            originalURL: self.originalInputURL
                        )
                        self.historyManager.addHistory(history)
                    }
                }
                
            } catch {
                await MainActor.run {
                    // 字幕加载失败,但允许视频播放
                    self.subtitleError = "字幕加载失败,但您仍可以观看视频"
                    self.isLoadingSubtitles = false
                    self.subtitles = []
                    
                    // 保存到历史记录(即使没有字幕)
                    if let title = self.videoTitle, let video = self.currentVideo {
                        let history = VideoHistory(
                            videoID: video.youtubeVideoID,
                            title: title,
                            originalURL: self.originalInputURL
                        )
                        self.historyManager.addHistory(history)
                    }
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
            return sorted.first
        }
        
        // 如果没有不分离的格式，暂时返回 nil
        // TODO: 未来可以实现音视频合并功能
        return nil
    }
    
    /// 从 URL 加载视频
    func loadVideoFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            subtitleError = "无效的视频 URL"
            return
        }
        
        
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
                    self?.isVideoReady = true
                    // 自动播放视频
                    self?.player?.play()
                    self?.isPlaying = true
                case .failed:
                    self?.isVideoReady = false
                    self?.subtitleError = "视频加载失败"
                case .unknown:
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
                }
            }
            .store(in: &cancellables)
    }
    
    /// 设置时间监听器(每0.033秒更新一次，约30fps，更平滑)
    private func setupTimeObserver() {
        // 使用更短的更新间隔，让进度条更精确、更流畅
        // 0.033秒 ≈ 30fps，人眼感知流畅
        // preferredTimescale 设置为 600 确保时间精度
        let interval = CMTime(seconds: 0.033, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            self?.updateCurrentSubtitle()
        }
    }
    
    /// 更新当前字幕(应用偏移量)
    private func updateCurrentSubtitle() {
        let adjustedTime = currentTime + subtitleOffset
        
        // 使用 lastIndex 而不是 firstIndex，以处理 YouTube 可能存在的字幕重叠情况。
        // 这样如果多个字幕块同时包含当前时间，会优先显示“最新”开始的那一个。
        if let index = subtitles.lastIndex(where: { $0.contains(time: adjustedTime) }) {
            if currentSubtitleIndex != index {
                currentSubtitleIndex = index
            }
            
            // 街溜子模式逻辑：在字幕快结束时触发
            if isStreetWandererMode {
                let sub = subtitles[index]
                // 距离结束还有 0.3 秒时触发朗读
                if adjustedTime >= sub.endTime - 0.3 && lastSpokenIndex != index {
                    handleStreetWandererPause(for: index)
                }
            }
        } else {
            currentSubtitleIndex = nil
            // 在字幕间隙重置说话记录，允许手动回跳后重读
            if lastSpokenIndex != nil {
                lastSpokenIndex = nil
            }
        }
    }
    
    /// 调整字幕偏移量
    func adjustSubtitleOffset(by delta: Double) {
        subtitleOffset += delta
        updateCurrentSubtitle()
    }
    
    /// 切换街溜子模式
    func toggleStreetWandererMode() {
        isStreetWandererMode.toggle()
        if !isStreetWandererMode {
            synthesizer.stopSpeaking(at: .immediate)
            lastSpokenIndex = nil
        }
    }
    
    private func handleStreetWandererPause(for index: Int) {
        guard isStreetWandererMode else { return }
        lastSpokenIndex = index
        
        // 暂停视频
        pauseVideo()
        
        // 稍等 0.1s 确保暂停生效再开始说话
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // 获取当前字幕的中文
            let chinese = self.subtitles[index].chineseText
            if !chinese.isEmpty {
                let utterance = AVSpeechUtterance(string: chinese)
                utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
                utterance.rate = 0.5
                utterance.volume = 1.0
                self.synthesizer.speak(utterance)
            } else {
                // 如果没中文，直接恢复播放
                self.playVideo()
            }
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isStreetWandererMode {
            playVideo()
        }
    }
    
    private func playVideo() {
        player?.play()
        isPlaying = true
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
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
        // 跳转时重置朗读状态，允许重复朗读当前句
        lastSpokenIndex = nil
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
