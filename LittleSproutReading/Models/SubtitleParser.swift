//
//  SubtitleParser.swift
//  LittleSproutReading
//
//  字幕解析器 - 支持SRT格式
//

import Foundation

class SubtitleParser {
    
    /// 解析SRT格式字幕文件
    static func parseSRT(from url: URL) -> [Subtitle] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ 无法读取字幕文件: \(url)")
            return []
        }
        
        return parseSRT(content: content)
    }
    
    /// 解析SRT格式字幕内容
    static func parseSRT(content: String) -> [Subtitle] {
        var subtitles: [Subtitle] = []
        
        // 按空行分割字幕块
        let blocks = content.components(separatedBy: "\n\n")
        
        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard lines.count >= 3 else { continue }
            
            // 第一行: 序号
            guard let index = Int(lines[0].trimmingCharacters(in: .whitespaces)) else { continue }
            
            // 第二行: 时间范围
            let timeRange = lines[1]
            guard let (startTime, endTime) = parseTimeRange(timeRange) else { continue }
            
            // 第三行及之后: 文本内容
            let textLines = Array(lines[2...])
            
            // 先清理所有HTML标签
            var cleanedLines: [String] = []
            for line in textLines {
                let cleaned = cleanFormatTags(line)
                if !cleaned.isEmpty {
                    cleanedLines.append(cleaned)
                }
            }
            
            // 分离中英文
            // 策略: 第一个包含中文的行是中文,其他是英文
            var englishText = ""
            var chineseText = ""
            var foundChinese = false
            
            for line in cleanedLines {
                if containsChinese(line) && !foundChinese {
                    // 第一次遇到中文行
                    chineseText = line
                    foundChinese = true
                } else if !containsChinese(line) {
                    // 英文行
                    englishText += (englishText.isEmpty ? "" : " ") + line
                }
            }
            
            let subtitle = Subtitle(
                index: index,
                startTime: startTime,
                endTime: endTime,
                englishText: englishText.trimmingCharacters(in: .whitespaces),
                chineseText: chineseText.trimmingCharacters(in: .whitespaces)
            )
            
            // 调试输出前几条字幕
            if index <= 3 {
                print("📝 字幕 #\(index):")
                print("  英文: [\(subtitle.englishText)]")
                print("  中文: [\(subtitle.chineseText)]")
            }
            
            subtitles.append(subtitle)
        }
        
        return subtitles
    }
    
    /// 解析时间范围 (00:00:21,000 --> 00:00:23,500)
    private static func parseTimeRange(_ timeRange: String) -> (Double, Double)? {
        let components = timeRange.components(separatedBy: " --> ")
        guard components.count == 2 else { return nil }
        
        guard let startTime = parseTimestamp(components[0]),
              let endTime = parseTimestamp(components[1]) else {
            return nil
        }
        
        return (startTime, endTime)
    }
    
    /// 解析时间戳 (00:00:21,000 -> 21.0秒)
    private static func parseTimestamp(_ timestamp: String) -> Double? {
        // SRT格式: 00:00:21,000
        let cleaned = timestamp.trimmingCharacters(in: .whitespaces)
        let parts = cleaned.replacingOccurrences(of: ",", with: ".").components(separatedBy: ":")
        
        guard parts.count == 3 else { return nil }
        
        guard let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else {
            return nil
        }
        
        return hours * 3600 + minutes * 60 + seconds
    }
    
    /// 判断字符串是否包含中文
    private static func containsChinese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value) {
                return true
            }
        }
        return false
    }
    
    /// 清理HTML/ASS格式标签
    private static func cleanFormatTags(_ text: String) -> String {
        var cleaned = text
        
        // 移除HTML标签 <font>, <b>, </font>, </b> 等
        // 使用非贪婪匹配,避免删除标签之间的内容
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+?>", with: "", options: .regularExpression)
        
        // 移除ASS样式标签 {\...}
        cleaned = cleaned.replacingOccurrences(of: "\\{[^}]+?\\}", with: "", options: .regularExpression)
        
        // 移除所有花括号(包括单独的和成对的)
        cleaned = cleaned.replacingOccurrences(of: "\\{\\}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\}", with: "")
        
        // 清理多余的空格和换行
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 再次检查并移除开头的{}
        if cleaned.hasPrefix("{}") {
            cleaned = String(cleaned.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
        
        return cleaned
    }
}
