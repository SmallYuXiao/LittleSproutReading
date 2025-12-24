//
//  ContentView.swift
//  LittleSproutReading
//
//  主视图 - YouTube 视频播放器
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var forceLandscape = false  // 强制横屏模式
    
    // 单词翻译弹窗状态（提升到顶层）
    @State private var selectedWord: String?
    @State private var wordPosition: CGRect?
    @State private var showTranslation = false
    
    init() {
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 内容区域
                    if let video = viewModel.currentVideo, video.isYouTube {
                        VStack(spacing: 0) {
                            // 导航栏（强制横屏时隐藏）
                            if !forceLandscape {
                                navigationBar
                            }
                            
                            // 视频和字幕内容
                            Group {
                                // 根据屏幕方向自动切换布局
                                let isLandscape = geometry.size.width > geometry.size.height
                                
                                if isLandscape || forceLandscape {
                                    // 横屏布局：视频在左，字幕在右
                                    HStack(spacing: 0) {
                                        // 左侧: 视频播放器 (60% 宽度)
                                        VideoPlayerView(
                                            viewModel: viewModel,
                                            forceLandscape: $forceLandscape
                                        )
                                        .frame(width: forceLandscape ? geometry.size.height * 0.6 : geometry.size.width * 0.6)
                                        
                                        // 右侧: 字幕列表 (40% 宽度)
                                        SubtitleListView(
                                            viewModel: viewModel,
                                            selectedWord: $selectedWord,
                                            wordPosition: $wordPosition,
                                            showTranslation: $showTranslation
                                        )
                                        .frame(width: forceLandscape ? geometry.size.height * 0.4 : geometry.size.width * 0.4)
                                    }
                                } else {
                                    // 竖屏布局：视频在上，字幕在下
                                    VStack(spacing: 0) {
                                        // 上方: 视频播放器 (40% 高度)
                                        VideoPlayerView(
                                            viewModel: viewModel,
                                            forceLandscape: $forceLandscape
                                        )
                                        .frame(height: geometry.size.height * 0.4)
                                        
                                        // 下方: 字幕列表 (60% 高度)
                                        SubtitleListView(
                                            viewModel: viewModel,
                                            selectedWord: $selectedWord,
                                            wordPosition: $wordPosition,
                                            showTranslation: $showTranslation
                                        )
                                        .frame(height: geometry.size.height * 0.6)
                                    }
                                }
                            }
                            .frame(
                                width: forceLandscape ? geometry.size.height : geometry.size.width,
                                height: forceLandscape ? geometry.size.width : nil
                            )
                            .rotationEffect(.degrees(forceLandscape ? 90 : 0))
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    } else {
                        // YouTube Web 浏览页面（全屏，顶部和底部贴合屏幕）
                        YouTubeWebBrowserView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 只允许向右滑动
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            // 如果滑动超过屏幕宽度的 1/3，则返回
                            if value.translation.width > geometry.size.width / 3 {
                                handleBack()
                            }
                            // 重置偏移
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                )
            }
            .overlay {
                // 单词翻译弹窗（全屏覆盖）
                if showTranslation, let word = selectedWord, let position = wordPosition {
                    WordTranslationPopup(
                        word: word,
                        wordPosition: position,
                        viewModel: viewModel,
                        isPresented: $showTranslation
                    )
                    .zIndex(999)  // 确保在最上层
                }
            }
        }
        .background(Color.black)
    }
    
    // MARK: - 导航栏
    private var navigationBar: some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: handleBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            // 视频标题（优先显示从 API 获取的标题）
            if let video = viewModel.currentVideo {
                Text(viewModel.videoTitle ?? video.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 200)
            }
            
            Spacer()
            
            // 菜单按钮
            Menu {
                // 街溜子模式开关
                Button(action: {
                    viewModel.toggleStreetWandererMode()
                }) {
                    Label(
                        viewModel.isStreetWandererMode ? "关闭街溜子模式" : "开启街溜子模式",
                        systemImage: viewModel.isStreetWandererMode ? "person.wave.2.fill" : "person.wave.2"
                    )
                }
                
                Divider()
                
                // 旋转屏幕
                Button(action: {
                    withAnimation {
                        forceLandscape.toggle()
                    }
                }) {
                    Label(
                        forceLandscape ? "退出横屏" : "横屏模式",
                        systemImage: "rotate.right"
                    )
                }
            } label: {
                ZStack {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    // 街溜子模式激活指示器
                    if viewModel.isStreetWandererMode {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - 返回操作
    private func handleBack() {
        // 停止播放
        viewModel.player?.pause()
        viewModel.player = nil
        // 清除当前视频
        viewModel.currentVideo = nil
        viewModel.subtitles = []
    }
}

#Preview {
    ContentView()
}
