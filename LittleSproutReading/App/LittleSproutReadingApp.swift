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
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                }
        }
    }
}

// 在同一文件中定义以确保可见性（解决文件未加入 Target 的问题）
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 异步配置音频会话，不阻塞启动
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupAudioSession()
        }
        
        return true
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            DispatchQueue.main.async {
            }
        } catch {
            DispatchQueue.main.async {
            }
        }
    }
}
