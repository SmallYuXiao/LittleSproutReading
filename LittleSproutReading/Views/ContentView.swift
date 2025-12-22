//
//  ContentView.swift
//  LittleSproutReading
//
//  主视图 - YouTube 视频播放器
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 内容区域
                if let video = viewModel.currentVideo, video.isYouTube {
                    // 播放页面
                    HStack(spacing: 0) {
                        // 左侧: 视频播放器 (60%)
                        VideoPlayerView(viewModel: viewModel)
                            .frame(width: geometry.size.width * 0.6)
                        
                        // 右侧: 字幕列表 (40%)
                        SubtitleListView(viewModel: viewModel)
                            .frame(width: geometry.size.width * 0.4)
                    }
                } else {
                    // YouTube URL 输入页面（全屏）
                    YouTubeInputView(viewModel: viewModel)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
