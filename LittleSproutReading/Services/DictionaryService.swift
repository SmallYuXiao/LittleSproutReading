//
//  DictionaryService.swift
//  LittleSproutReading
//
//  词典服务 - 集成vveai API
//

import Foundation
import AVFoundation

class DictionaryService: ObservableObject {
    static let shared = DictionaryService()
    
    private let apiKey: String
    private let baseURL: String
    private let cache = NSCache<NSString, WordDefinition>()
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var favorites: Set<String> = []
    
    private init() {
        // 从Config.plist读取API Key
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) {
            self.apiKey = config["VVEAI_API_KEY"] as? String ?? ""
            self.baseURL = config["VVEAI_API_BASE_URL"] as? String ?? "https://api.vveai.com/v1"
        } else {
            // 如果没有Config.plist,尝试从环境变量读取
            self.apiKey = ProcessInfo.processInfo.environment["VVEAI_API_KEY"] ?? ""
            self.baseURL = ProcessInfo.processInfo.environment["VVEAI_API_BASE_URL"] ?? "https://api.vveai.com/v1"
        }
        
        
        loadFavorites()
    }
    
    /// 查询单词释义(使用AI API)
    func lookupWord(_ word: String) async throws -> WordDefinition {
        let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        
        // 检查缓存
        if let cached = cache.object(forKey: cleanWord as NSString) {
            return cached
        }
        
        // 调用AI API
        let definition = try await fetchFromAI(word: cleanWord)
        
        // 缓存结果
        cache.setObject(definition, forKey: cleanWord as NSString)
        
        return definition
    }
    
    /// 调用vveai API查询单词
    private func fetchFromAI(word: String) async throws -> WordDefinition {
        guard !apiKey.isEmpty else {
            throw DictionaryError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        请提供单词 "\(word)" 的详细释义,以JSON格式返回:
        {
          "word": "\(word)",
          "phonetic": "音标",
          "definitions": [
            {
              "partOfSpeech": "词性(如 n., v., adj.)",
              "meanings": ["主要释义"]
            }
          ],
          "examples": ["例句1", "例句2"],
          "chineseTranslation": "中文翻译"
        }
        要求：
        1. 只返回1个词性的1个主要释义
        2. 提供2个简短易懂的英文例句
        3. chineseTranslation 只返回简洁的中文翻译(1-3个词)
        4. 只返回JSON,不要其他内容
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.networkError
        }
        
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
            }
            throw DictionaryError.networkError
        }
        
        // 打印原始响应
        if let responseString = String(data: data, encoding: .utf8) {
        }
        
        // 解析AI响应
        do {
            let aiResponse = try JSONDecoder().decode(AITranslationResponse.self, from: data)
            guard let content = aiResponse.choices.first?.message.content else {
                throw DictionaryError.invalidResponse
            }
            
            
            // 从AI返回的JSON中提取WordDefinition
            guard let jsonData = content.data(using: .utf8) else {
                throw DictionaryError.invalidResponse
            }
            
            var definition = try JSONDecoder().decode(WordDefinition.self, from: jsonData)
            
            // 检查是否已收藏
            definition.isFavorite = favorites.contains(word)
            
            return definition
        } catch {
            throw DictionaryError.invalidResponse
        }
    }
    
    /// 朗读单词/例句（防空字符串，统一音频会话）
    func pronounce(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        DispatchQueue.main.async {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? session.setActive(true, options: .notifyOthersOnDeactivation)
            
            // 停止当前朗读，避免叠音和空缓冲
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            
            let utterance = AVSpeechUtterance(string: trimmed)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.48
            self.synthesizer.speak(utterance)
        }
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ word: String) {
        let cleanWord = word.lowercased()
        if favorites.contains(cleanWord) {
            favorites.remove(cleanWord)
        } else {
            favorites.insert(cleanWord)
        }
        saveFavorites()
    }
    
    /// 保存生词本
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: "favoriteWords")
    }
    
    /// 加载生词本
    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favoriteWords") as? [String] {
            favorites = Set(saved)
        }
    }
}

// MARK: - 错误类型
enum DictionaryError: LocalizedError {
    case missingAPIKey
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "未配置API Key,请在.env文件中设置VVEAI_API_KEY"
        case .networkError:
            return "网络请求失败"
        case .invalidResponse:
            return "无效的API响应"
        }
    }
}
