//
//  LittleSproutReadingApp.swift
//  LittleSproutReading
//
//  Created on 2025-12-21.
//

import SwiftUI
import AVFoundation

@main
struct LittleSproutReadingApp: App {
    // 注入 AppDelegate 以处理后台音频配置
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// 在同一文件中定义以确保可见性（解决文件未加入 Target 的问题）
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupAudioSession()
        return true
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ AVAudioSession 配置成功")
        } catch {
            print("❌ AVAudioSession 配置失败: \(error.localizedDescription)")
        }
    }
}
