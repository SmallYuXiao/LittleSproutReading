//
//  YouTubeSubtitleService.swift
//  LittleSproutReading
//
//  YouTube 字幕获取服务
//

import Foundation

enum YouTubeSubtitleError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case noSubtitles
    case parseError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 YouTube URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .noSubtitles:
            return "该视频没有可用的字幕"
        case .parseError:
            return "字幕解析失败"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}

class YouTubeSubtitleService {
    static let shared = YouTubeSubtitleService()
    
    // 后端服务地址 - Render 云端部署
    private let baseURL = "https://littlesproutreading.onrender.com"
    
    private init() {}
    
    /// 获取 YouTube 视频字幕
    /// - Parameters:
    ///   - videoID: YouTube Video ID
    ///   - language: 语言代码(可选,默认英文)
    /// - Returns: 字幕数组
    func fetchSubtitles(videoID: String, language: String = "en") async throws -> [Subtitle] {
        // 构建 URL
        var components = URLComponents(string: "\(baseURL)/api/subtitles/\(videoID)")
        components?.queryItems = [URLQueryItem(name: "lang", value: language)]
        
        guard let url = components?.url else {
            throw YouTubeSubtitleError.invalidURL
        }
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeSubtitleError.networkError(NSError(domain: "Invalid response", code: -1))
        }
        
        // 解析响应
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(YouTubeSubtitleResponse.self, from: data)
        
        if !apiResponse.success {
            throw YouTubeSubtitleError.serverError(apiResponse.error ?? "Unknown error")
        }
        
        guard let srtContent = apiResponse.subtitle_srt else {
            throw YouTubeSubtitleError.noSubtitles
        }
        
        // 解析 SRT 字幕
        let subtitles = SubtitleParser.parseSRT(content: srtContent)
        
        return subtitles
    }
    
    /// 获取 YouTube 视频的直接播放 URL
    /// ⚠️ 警告: 此功能违反 YouTube 服务条款,仅供学习使用
    func fetchVideoURL(videoID: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/video-url/\(videoID)") else {
            throw YouTubeSubtitleError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(VideoURLResponse.self, from: data)
        
        if !response.success {
            throw YouTubeSubtitleError.serverError(response.error ?? "Unknown error")
        }
        
        guard let videoURL = response.video_url else {
            throw YouTubeSubtitleError.serverError("No video URL returned")
        }
        
        return videoURL
    }
    
    /// 获取视频可用的字幕语言列表
    func fetchAvailableLanguages(videoID: String) async throws -> [SubtitleLanguage] {
        guard let url = URL(string: "\(baseURL)/api/languages/\(videoID)") else {
            throw YouTubeSubtitleError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(LanguageResponse.self, from: data)
        
        if !response.success {
            throw YouTubeSubtitleError.serverError(response.error ?? "Unknown error")
        }
        
        return response.languages ?? []
    }
    
    /// 检查服务是否可用
    func checkServiceHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            return false
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(HealthResponse.self, from: data)
            return response.status == "ok"
        } catch {
            return false
        }
    }
}

// MARK: - Response Models

struct YouTubeSubtitleResponse: Codable {
    let success: Bool
    let video_id: String?
    let language: String?
    let language_name: String?
    let is_generated: Bool?
    let subtitle_srt: String?
    let subtitle_count: Int?
    let available_languages: [SubtitleLanguage]?
    let error: String?
}

struct SubtitleLanguage: Codable, Identifiable {
    var id: String { code }
    let code: String
    let name: String
    let is_generated: Bool
    let is_translatable: Bool
}

struct LanguageResponse: Codable {
    let success: Bool
    let video_id: String?
    let languages: [SubtitleLanguage]?
    let error: String?
}

struct HealthResponse: Codable {
    let status: String
    let service: String?
    let version: String?
}

struct VideoURLResponse: Codable {
    let success: Bool
    let video_id: String?
    let title: String?
    let duration: Double?
    let video_url: String?
    let thumbnail: String?
    let description: String?
    let error: String?
}

// MARK: - iiiLab Service Methods

extension YouTubeSubtitleService {
    /// 使用 iiiLab 服务获取完整的 YouTube 视频信息（包括字幕）
    /// - Parameter videoID: YouTube Video ID
    /// - Returns: 包含视频信息、播放地址和字幕的完整数据
    func fetchVideoInfoWithSubtitles(videoID: String) async throws -> YouTubeVideoInfoResponse {
        guard let url = URL(string: "\(baseURL)/api/youtube-info/\(videoID)") else {
            throw YouTubeSubtitleError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(YouTubeVideoInfoResponse.self, from: data)
        
        if !response.success {
            throw YouTubeSubtitleError.serverError(response.error ?? "Unknown error")
        }
        
        return response
    }
    
    /// 从字幕 URL 下载 SRT 内容并解析
    /// - Parameter urlString: 字幕 URL
    /// - Returns: 解析后的字幕数组
    func downloadSubtitleContent(from urlString: String) async throws -> [Subtitle] {
        guard let url = URL(string: urlString) else {
            throw YouTubeSubtitleError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let srtContent = String(data: data, encoding: .utf8) else {
            throw YouTubeSubtitleError.parseError
        }
        
        // 解析 SRT 字幕
        return SubtitleParser.parseSRT(content: srtContent)
    }
}

// MARK: - iiiLab Response Models

struct YouTubeVideoInfoResponse: Codable {
    let success: Bool
    let title: String?
    let thumbnail: String?
    let duration: Int?
    let formats: [VideoFormat]?
    let subtitles: [VideoSubtitle]?
    let error: String?
}

struct VideoFormat: Codable, Identifiable {
    var id: String { quality }
    let quality: String
    let quality_value: Int
    let quality_note: String?
    let format: String
    let video_url: String
    let audio_url: String?
    let filesize: Int
    let has_audio: Bool
    let height: Int
    let separate: Bool
}

struct VideoSubtitle: Codable, Identifiable {
    var id: String { language }
    let language: String
    let language_name: String
    let url: String
    let format: String
}

