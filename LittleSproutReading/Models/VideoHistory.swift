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
    
    init(videoID: String, title: String, thumbnailURL: String? = nil) {
        self.id = UUID()
        self.videoID = videoID
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.watchedAt = Date()
    }
}
