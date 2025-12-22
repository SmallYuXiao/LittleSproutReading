//
//  Video.swift
//  LittleSproutReading
//
//  YouTube 视频模型
//

import Foundation

struct Video: Identifiable {
    let id = UUID()
    let youtubeVideoID: String
    let title: String
    
    /// 始终返回 true，因为现在只支持 YouTube 视频
    var isYouTube: Bool {
        return true
    }
    
    /// 初始化 YouTube 视频
    init(youtubeVideoID: String, title: String) {
        self.youtubeVideoID = youtubeVideoID
        self.title = title
    }
}
