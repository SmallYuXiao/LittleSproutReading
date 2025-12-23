//
//  HistoryManager.swift
//  LittleSproutReading
//
//  历史记录管理器
//

import Foundation
import Combine

class HistoryManager: ObservableObject {
    @Published var histories: [VideoHistory] = []
    
    private let maxHistoryCount = 20  // 最多保存 20 条
    private let userDefaultsKey = "videoHistories"
    
    init() {
        print("📜 [STARTUP] HistoryManager init 开始: \(Date())")
        loadHistories()
        print("📜 [STARTUP] HistoryManager init 结束: \(Date())")
    }
    
    /// 添加历史记录
    func addHistory(_ history: VideoHistory) {
        // 移除相同 videoID 的旧记录
        histories.removeAll { $0.videoID == history.videoID }
        
        // 添加到开头（最新的在前面）
        histories.insert(history, at: 0)
        
        // 限制数量
        if histories.count > maxHistoryCount {
            histories = Array(histories.prefix(maxHistoryCount))
        }
        
        saveHistories()
        print("✅ 已保存历史记录: \(history.title)")
    }
    
    /// 删除单条历史记录
    func deleteHistory(_ history: VideoHistory) {
        print("🗑️ [DEBUG] 开始删除历史记录: \(history.title)")
        print("🗑️ [DEBUG] 删除前数量: \(histories.count)")
        
        histories.removeAll { $0.id == history.id }
        
        print("🗑️ [DEBUG] 删除后数量: \(histories.count)")
        saveHistories()
        print("✅ 已删除历史记录: \(history.title)")
    }
    
    /// 清空所有历史记录
    func clearAll() {
        print("🗑️ [DEBUG] 开始清空所有历史记录")
        print("🗑️ [DEBUG] 清空前数量: \(histories.count)")
        
        histories.removeAll()
        
        print("🗑️ [DEBUG] 清空后数量: \(histories.count)")
        saveHistories()
        print("✅ 已清空所有历史记录")
    }
    
    /// 保存到 UserDefaults
    private func saveHistories() {
        if let encoded = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// 从 UserDefaults 加载
    private func loadHistories() {
        print("📜 [STARTUP] loadHistories 开始: \(Date())")
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([VideoHistory].self, from: data) {
            histories = decoded
            print("📜 已加载 \(histories.count) 条历史记录")
        }
        print("📜 [STARTUP] loadHistories 结束: \(Date())")
    }
}

// MARK: - 辅助函数

extension HistoryManager {
    /// 计算时间差显示
    func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "刚刚"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))分钟前"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))小时前"
        } else if seconds < 604800 {
            return "\(Int(seconds / 86400))天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
}
