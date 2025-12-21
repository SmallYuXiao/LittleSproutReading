//
//  Video.swift
//  LittleSproutReading
//
//  视频资源模型
//

import Foundation

struct Video: Identifiable {
    let id = UUID()
    let fileName: String
    let title: String
    let subtitleFileName: String
    
    /// 获取视频文件URL
    var videoURL: URL? {
        // 尝试从Bundle加载
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") {
            return url
        }
        // 尝试从Resources/Videos目录加载
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "Resources/Videos") {
            return url
        }
        // 尝试直接路径
        let resourcePath = Bundle.main.resourcePath ?? ""
        let videoPath = (resourcePath as NSString).appendingPathComponent("Resources/Videos/\(fileName).mp4")
        if FileManager.default.fileExists(atPath: videoPath) {
            return URL(fileURLWithPath: videoPath)
        }
        return nil
    }
    
    /// 获取字幕文件URL
    var subtitleURL: URL? {
        // 尝试从Bundle加载
        if let url = Bundle.main.url(forResource: subtitleFileName, withExtension: "srt") {
            return url
        }
        // 尝试从Resources/Subtitles目录加载
        if let url = Bundle.main.url(forResource: subtitleFileName, withExtension: "srt", subdirectory: "Resources/Subtitles") {
            return url
        }
        // 尝试直接路径
        let resourcePath = Bundle.main.resourcePath ?? ""
        let subtitlePath = (resourcePath as NSString).appendingPathComponent("Resources/Subtitles/\(subtitleFileName).srt")
        if FileManager.default.fileExists(atPath: subtitlePath) {
            return URL(fileURLWithPath: subtitlePath)
        }
        return nil
    }
}

// MARK: - 测试数据
extension Video {
    static let sample = Video(
        fileName: "sample",
        title: "Sample Video",
        subtitleFileName: "sample"
    )
}
