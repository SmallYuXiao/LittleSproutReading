//
//  VideoHistory.swift
//  LittleSproutReading
//
//  视频历史记录模型
//

import Foundation

struct VideoHistory: Identifiable, Codable {
    let id: UUID
    let videoID: String
    let title: String
    let thumbnailURL: String?
    let watchedAt: Date
    let originalURL: String  // 用户输入的完整 URL
    
    init(videoID: String, title: String, originalURL: String, thumbnailURL: String? = nil) {
        self.id = UUID()
        self.videoID = videoID
        self.title = title
        self.originalURL = originalURL
        self.thumbnailURL = thumbnailURL
        self.watchedAt = Date()
    }
    
    // 兼容旧数据：如果 originalURL 为空，从 videoID 构建默认 URL
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        videoID = try container.decode(String.self, forKey: .videoID)
        title = try container.decode(String.self, forKey: .title)
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        watchedAt = try container.decode(Date.self, forKey: .watchedAt)
        
        // 兼容性处理：如果没有 originalURL，从 videoID 构建
        if let url = try container.decodeIfPresent(String.self, forKey: .originalURL) {
            originalURL = url
        } else {
            originalURL = "https://www.youtube.com/watch?v=\(videoID)"
        }
    }
}
