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
                if containsChinese(line) {
                    // 收集所有中文行
                    chineseText += (chineseText.isEmpty ? "" : " ") + line
                    foundChinese = true
                } else {
                    // 收集所有非中文行（英文）
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
    
    /// 解析 VTT 格式字幕
    static func parseVTT(content: String) -> [Subtitle] {
        var subtitles: [Subtitle] = []
        
        // 按空行分割字幕块
        let blocks = content.components(separatedBy: "\n\n")
        var index = 1
        
        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard lines.count >= 2 else { continue }
            
            // 跳过 WEBVTT 头和样式定义
            if lines[0].contains("WEBVTT") || lines[0].contains("STYLE") || lines[0].contains("NOTE") {
                continue
            }
            
            // VTT 格式: 时间行可能在第一行或第二行
            var timeLineIndex = 0
            if lines[0].contains("-->") {
                timeLineIndex = 0
            } else if lines.count > 1 && lines[1].contains("-->") {
                timeLineIndex = 1
            } else {
                continue
            }
            
            // 解析时间范围
            let timeLine = lines[timeLineIndex]
            guard let (startTime, endTime) = parseVTTTimeRange(timeLine) else { continue }
            
            // 文本内容在时间行之后，用空格连接多行
            let textLines = Array(lines[(timeLineIndex + 1)...])
            let text = textLines.joined(separator: " ")
            let cleanedText = cleanFormatTags(text)
            
            // 跳过空文本
            guard !cleanedText.isEmpty else { continue }
            
            // 分离中英文
            var englishText = ""
            var chineseText = ""
            
            if containsChinese(cleanedText) {
                chineseText = cleanedText
            } else {
                englishText = cleanedText
            }
            
            let subtitle = Subtitle(
                index: index,
                startTime: startTime,
                endTime: endTime,
                englishText: englishText,
                chineseText: chineseText
            )
            
            subtitles.append(subtitle)
            index += 1
        }
        
        return subtitles
    }
    
    /// 解析 XML 格式字幕 (YouTube TTML)
    static func parseXML(content: String) -> [Subtitle] {
        // 临时存储所有片段
        struct TextFragment {
            let startTime: Double
            let endTime: Double
            let text: String
        }
        
        var fragments: [TextFragment] = []
        
        // 使用正则提取所有 <text> 标签
        let pattern = "<text[^>]*start=\"([^\"]+)\"[^>]*dur=\"([^\"]+)\"[^>]*>([^<]+)</text>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsString = content as NSString
        let results = regex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
        
        // 先提取所有片段
        for match in results {
            if match.numberOfRanges >= 4 {
                let startStr = nsString.substring(with: match.range(at: 1))
                let durStr = nsString.substring(with: match.range(at: 2))
                let text = nsString.substring(with: match.range(at: 3))
                
                guard let startTime = Double(startStr),
                      let duration = Double(durStr) else { continue }
                
                let endTime = startTime + duration
                let cleanedText = cleanFormatTags(text)
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&#39;", with: "'")
                
                if !cleanedText.isEmpty {
                    fragments.append(TextFragment(startTime: startTime, endTime: endTime, text: cleanedText))
                }
            }
        }
        
        // 🎯 合并连续的短片段成完整句子
        print("📊 XML解析: 提取到 \(fragments.count) 个文本片段")
        if fragments.count > 0 {
            print("   示例片段 [前5个]: ")
            for (i, frag) in fragments.prefix(5).enumerated() {
                print("   [\(i+1)] \(frag.startTime)s: \"\(frag.text)\"")
            }
        }
        
        var subtitles: [Subtitle] = []
        var currentText = ""
        var currentStartTime: Double = 0
        var currentEndTime: Double = 0
        var index = 1
        
        for (i, fragment) in fragments.enumerated() {
            if currentText.isEmpty {
                // 开始新的字幕
                currentText = fragment.text
                currentStartTime = fragment.startTime
                currentEndTime = fragment.endTime
            } else {
                // 判断是否应该合并到当前字幕
                let gap = fragment.startTime - currentEndTime
                
                // 如果时间间隔小于 0.5 秒，且累计文本不太长（少于 100 字符），则合并
                if gap < 0.5 && currentText.count < 100 {
                    // 🎯 智能合并逻辑：
                    // 1. 如果 fragment 是单个字符或很短（1-2个字符），直接连接不加空格
                    // 2. 如果 fragment 是完整单词（3个字符以上），在单词之间添加空格
                    let isShortFragment = fragment.text.count <= 2
                    let needsSpace = !isShortFragment && 
                                   fragment.text.first?.isLetter == true && 
                                   currentText.last?.isLetter == true
                    
                    if needsSpace {
                        currentText += " " + fragment.text
                    } else {
                        currentText += fragment.text
                    }
                    currentEndTime = fragment.endTime
                } else {
                    // 保存当前字幕
                    saveSubtitle()
                    
                    // 开始新的字幕
                    currentText = fragment.text
                    currentStartTime = fragment.startTime
                    currentEndTime = fragment.endTime
                }
            }
            
            // 最后一个片段
            if i == fragments.count - 1 && !currentText.isEmpty {
                saveSubtitle()
            }
        }
        
        func saveSubtitle() {
            // 分离中英文
            var englishText = ""
            var chineseText = ""
            
            if containsChinese(currentText) {
                chineseText = currentText
            } else {
                englishText = currentText
            }
            
            let subtitle = Subtitle(
                index: index,
                startTime: currentStartTime,
                endTime: currentEndTime,
                englishText: englishText,
                chineseText: chineseText
            )
            
            subtitles.append(subtitle)
            
            // 打印前几条合并后的字幕
            if index <= 3 {
                print("   ✅ 合并后字幕 #\(index): \"\(englishText.isEmpty ? chineseText : englishText)\"")
            }
            
            index += 1
            currentText = ""
        }
        
        print("📊 XML解析完成: 合并成 \(subtitles.count) 条字幕")
        return subtitles
    }
    
    /// 解析 VTT 时间范围 (00:00:21.000 --> 00:00:23.500)
    private static func parseVTTTimeRange(_ timeRange: String) -> (Double, Double)? {
        let components = timeRange.components(separatedBy: " --> ")
        guard components.count == 2 else { return nil }
        
        guard let startTime = parseVTTTimestamp(components[0]),
              let endTime = parseVTTTimestamp(components[1]) else {
            return nil
        }
        
        return (startTime, endTime)
    }
    
    /// 解析 VTT 时间戳 (00:00:21.000 -> 21.0秒)
    private static func parseVTTTimestamp(_ timestamp: String) -> Double? {
        // VTT 格式: 00:00:21.000 或 00:21.000
        let cleaned = timestamp.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleaned.components(separatedBy: ":")
        
        if parts.count == 3 {
            // HH:MM:SS.mmm
            guard let hours = Double(parts[0]),
                  let minutes = Double(parts[1]),
                  let seconds = Double(parts[2]) else {
                return nil
            }
            return hours * 3600 + minutes * 60 + seconds
        } else if parts.count == 2 {
            // MM:SS.mmm
            guard let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else {
                return nil
            }
            return minutes * 60 + seconds
        }
        
        return nil
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
