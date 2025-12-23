//
//  YouTubeURLParser.swift
//  LittleSproutReading
//
//  YouTube URL 解析工具
//

import Foundation

struct YouTubeURLParser {
    /// 从 URL 字符串中提取 YouTube Video ID
    /// 支持的格式:
    /// - https://www.youtube.com/watch?v=VIDEO_ID
    /// - https://youtu.be/VIDEO_ID
    /// - https://m.youtube.com/watch?v=VIDEO_ID
    /// - https://www.youtube.com/embed/VIDEO_ID
    /// - https://www.youtube.com/shorts/VIDEO_ID
    static func extractVideoID(from urlString: String) -> String? {
        print("🔍 [URLParser] 解析 URL: \(urlString)")
        
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else {
            print("❌ [URLParser] 无效的 URL")
            return nil
        }
        
        let host = url.host?.lowercased() ?? ""
        let path = url.path
        
        print("   Host: \(host)")
        print("   Path: \(path)")
        
        // 格式 1: youtu.be/VIDEO_ID
        if host.contains("youtu.be") {
            let videoID = url.lastPathComponent
            let result = isValidVideoID(videoID) ? videoID : nil
            print("   格式: youtu.be")
            print("   结果: \(result ?? "nil")")
            return result
        }
        
        // 格式 2: youtube.com/watch?v=VIDEO_ID
        if host.contains("youtube.com") {
            // 检查是否是 /watch 路径
            if path.contains("/watch") {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems,
                   let videoID = queryItems.first(where: { $0.name == "v" })?.value {
                    let result = isValidVideoID(videoID) ? videoID : nil
                    print("   格式: youtube.com/watch")
                    print("   结果: \(result ?? "nil")")
                    return result
                }
            }
            
            // 格式 3: youtube.com/embed/VIDEO_ID
            if path.contains("/embed/") {
                let pathComponents = url.pathComponents
                if let embedIndex = pathComponents.firstIndex(of: "embed"),
                   embedIndex + 1 < pathComponents.count {
                    let videoID = pathComponents[embedIndex + 1]
                    let result = isValidVideoID(videoID) ? videoID : nil
                    print("   格式: youtube.com/embed")
                    print("   结果: \(result ?? "nil")")
                    return result
                }
            }
            
            // 格式 4: youtube.com/v/VIDEO_ID
            if path.contains("/v/") {
                let pathComponents = url.pathComponents
                if let vIndex = pathComponents.firstIndex(of: "v"),
                   vIndex + 1 < pathComponents.count {
                    let videoID = pathComponents[vIndex + 1]
                    let result = isValidVideoID(videoID) ? videoID : nil
                    print("   格式: youtube.com/v")
                    print("   结果: \(result ?? "nil")")
                    return result
                }
            }
            
            // 格式 5: youtube.com/shorts/VIDEO_ID
            if path.contains("/shorts/") {
                let pathComponents = url.pathComponents
                if let shortsIndex = pathComponents.firstIndex(of: "shorts"),
                   shortsIndex + 1 < pathComponents.count {
                    let videoID = pathComponents[shortsIndex + 1]
                    let result = isValidVideoID(videoID) ? videoID : nil
                    print("   格式: youtube.com/shorts")
                    print("   结果: \(result ?? "nil")")
                    return result
                }
            }
        }
        
        print("   ❌ 不匹配任何已知格式")
        return nil
    }
    
    /// 验证 Video ID 格式
    /// YouTube Video ID 通常是 11 个字符的字母数字组合
    private static func isValidVideoID(_ videoID: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_-]{11}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: videoID.utf16.count)
        return regex?.firstMatch(in: videoID, range: range) != nil
    }
    
    /// 验证 URL 是否为有效的 YouTube URL
    static func isValidYouTubeURL(_ urlString: String) -> Bool {
        return extractVideoID(from: urlString) != nil
    }
}
