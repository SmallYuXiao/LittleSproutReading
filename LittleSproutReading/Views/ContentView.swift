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
                    // 根据屏幕方向自动切换布局
                    let isLandscape = geometry.size.width > geometry.size.height
                    
                    if isLandscape {
                        // 横屏布局：视频在左，字幕在右
                        HStack(spacing: 0) {
                            // 左侧: 视频播放器 (60%)
                            VideoPlayerView(viewModel: viewModel)
                                .frame(width: geometry.size.width * 0.6)
                            
                            // 右侧: 字幕列表 (40%)
                            SubtitleListView(viewModel: viewModel)
                                .frame(width: geometry.size.width * 0.4)
                        }
                    } else {
                        // 竖屏布局：视频在上，字幕在下
                        VStack(spacing: 0) {
                            // 上方: 视频播放器 (40% 高度)
                            VideoPlayerView(viewModel: viewModel)
                                .frame(height: geometry.size.height * 0.4)
                            
                            // 下方: 字幕列表 (60% 高度)
                            SubtitleListView(viewModel: viewModel)
                                .frame(height: geometry.size.height * 0.6)
                        }
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
