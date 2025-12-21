//
//  Subtitle.swift
//  LittleSproutReading
//
//  字幕数据模型
//

import Foundation

/// 单个单词的时间信息
struct SubtitleWord: Identifiable, Codable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
    
    enum CodingKeys: String, CodingKey {
        case text, startTime, endTime
    }
}

/// 字幕条目
struct Subtitle: Identifiable, Codable {
    let id = UUID()
    let index: Int
    let startTime: Double
    let endTime: Double
    let englishText: String
    let chineseText: String
    var words: [SubtitleWord]
    
    enum CodingKeys: String, CodingKey {
        case index, startTime, endTime, englishText, chineseText, words
    }
    
    /// 判断给定时间是否在此字幕的时间范围内
    func contains(time: Double) -> Bool {
        return time >= startTime && time <= endTime
    }
    
    /// 获取当前时间对应的单词索引
    func currentWordIndex(at time: Double) -> Int? {
        guard contains(time: time) else { return nil }
        return words.firstIndex { $0.startTime <= time && time <= $0.endTime }
    }
    
    /// 初始化时自动分词并计算单词时间
    init(index: Int, startTime: Double, endTime: Double, englishText: String, chineseText: String) {
        self.index = index
        self.startTime = startTime
        self.endTime = endTime
        self.englishText = englishText
        self.chineseText = chineseText
        
        // 分词并计算每个单词的时间范围
        let wordTexts = englishText.split(separator: " ").map { String($0) }
        let duration = endTime - startTime
        let wordDuration = duration / Double(wordTexts.count)
        
        self.words = wordTexts.enumerated().map { index, text in
            let wordStart = startTime + Double(index) * wordDuration
            let wordEnd = wordStart + wordDuration
            return SubtitleWord(text: text, startTime: wordStart, endTime: wordEnd)
        }
    }
}
