//
//  ContentView.swift
//  LittleSproutReading
//
//  主视图 - 横屏布局
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左侧: 视频播放器 (60%)
                VideoPlayerView(viewModel: viewModel)
                    .frame(width: geometry.size.width * 0.6)
                
                // 右侧: 字幕列表 (40%)
                SubtitleListView(viewModel: viewModel)
                    .frame(width: geometry.size.width * 0.4)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            // 加载示例视频
            viewModel.loadVideo(.sample)
        }
    }
}

#Preview {
    ContentView()
}
