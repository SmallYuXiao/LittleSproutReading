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
                    
                    ZStack(alignment: .topLeading) {
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
                        
                        // 返回按钮（左上角）
                        Button(action: {
                            // 停止播放
                            viewModel.player?.pause()
                            viewModel.player = nil
                            // 清除当前视频
                            viewModel.currentVideo = nil
                            viewModel.subtitles = []
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("返回")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                        .padding(16)
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
