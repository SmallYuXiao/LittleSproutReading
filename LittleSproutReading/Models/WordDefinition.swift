//
//  WordDefinition.swift
//  LittleSproutReading
//
//  单词释义数据模型
//

import Foundation

/// 单词释义
class WordDefinition: Identifiable, Codable {
    let id = UUID()
    let word: String
    let phonetic: String?
    let definitions: [Definition]
    let examples: [String]  // 例句列表
    let chineseTranslation: String  // 中文翻译
    var isFavorite: Bool = false
    
    struct Definition: Codable {
        let partOfSpeech: String  // 词性: n., v., adj. 等
        let meanings: [String]     // 释义列表
    }
    
    enum CodingKeys: String, CodingKey {
        case word, phonetic, definitions, examples, chineseTranslation, isFavorite
    }
    
    init(word: String, phonetic: String?, definitions: [Definition], examples: [String] = [], chineseTranslation: String = "", isFavorite: Bool = false) {
        self.word = word
        self.phonetic = phonetic
        self.definitions = definitions
        self.examples = examples
        self.chineseTranslation = chineseTranslation
        self.isFavorite = isFavorite
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        word = try container.decode(String.self, forKey: .word)
        phonetic = try container.decodeIfPresent(String.self, forKey: .phonetic)
        definitions = try container.decode([Definition].self, forKey: .definitions)
        examples = try container.decodeIfPresent([String].self, forKey: .examples) ?? []
        chineseTranslation = try container.decodeIfPresent(String.self, forKey: .chineseTranslation) ?? ""
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}

/// AI API 响应模型
struct AITranslationResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
