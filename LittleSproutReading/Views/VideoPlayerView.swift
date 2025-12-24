//
//  VideoPlayerView.swift
//  LittleSproutReading
//
//  视频播放器视图
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Binding var forceLandscape: Bool  // 强制横屏模式绑定
    
    @State private var showControls = true  // 控制栏显示状态
    @State private var hideControlsTask: DispatchWorkItem?  // 自动隐藏任务
    
    var body: some View {
        // 使用 ZStack 让控制条浮动在视频上方
        ZStack(alignment: .bottom) {
            // 视频播放器（占满整个区域）
            ZStack {
                // 背景（始终显示）
                Rectangle()
                    .fill(Color.black)
                
                // 视频播放器（如果已加载）
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .background(Color.clear)
                }
                
                // 加载状态覆盖层（在视频未就绪或字幕加载中时显示）
                if !viewModel.isVideoReady || viewModel.isLoadingSubtitles {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(2.0)
                        
                        VStack(spacing: 8) {
                            if !viewModel.isVideoReady && viewModel.isLoadingSubtitles {
                                Text("正在加载视频...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("获取视频信息和字幕")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if !viewModel.isVideoReady {
                                Text("缓冲视频中...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("正在加载视频流")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if viewModel.isLoadingSubtitles {
                                Text("加载字幕中...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                // 错误提示覆盖层
                if let error = viewModel.subtitleError {
                    VStack(spacing: 24) {
                        // 错误图标
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        // 错误信息
                        VStack(spacing: 12) {
                            Text("加载失败")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(error)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Text("3秒后自动返回...")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.top, 8)
                        }
                        
                        // 手动返回按钮
                        Button(action: {
                            print("👆 [VideoPlayer] 用户点击立即返回")
                            viewModel.currentVideo = nil
                            viewModel.subtitles = []
                            viewModel.subtitleError = nil
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left")
                                Text("立即返回")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(25)
                        }
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.95))
                }
            }
            .contentShape(Rectangle())  // 让整个区域可点击
            .onTapGesture {
                // 点击视频区域切换控制栏显示
                toggleControls()
            }
            .onAppear {
                // 初始显示控制栏，5秒后自动隐藏
                scheduleHideControls()
            }
            
            // 播放控制条（浮动在底部，可自动隐藏）
            if showControls {
                controlsView
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - 控制栏显示/隐藏逻辑
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            scheduleHideControls()
        }
    }
    
    private func scheduleHideControls() {
        // 取消之前的隐藏任务
        hideControlsTask?.cancel()
        
        // 创建新的隐藏任务（5秒后执行）
        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
        hideControlsTask = task
        
        // 5秒后执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: task)
    }
    
    // MARK: - 播放控制
    private var controlsView: some View {
        VStack(spacing: 12) {
            // 简化的进度指示器（小圆点）
            progressIndicator
            
            // 时间显示
            HStack {
                Text(viewModel.formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(viewModel.formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - 进度指示器（小圆点样式）
    private var progressIndicator: some View {
        let safeDuration = viewModel.duration.isFinite && viewModel.duration > 0 ? viewModel.duration : 1.0
        let safeCurrentTime = min(max(viewModel.currentTime, 0), safeDuration)
        let progress = safeDuration > 0 ? safeCurrentTime / safeDuration : 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // 已播放进度
                Rectangle()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .cornerRadius(2)
                
                // 进度指示小圆点
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: geometry.size.width * progress - 6)
            }
        }
        .frame(height: 12)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newProgress = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                    viewModel.seek(to: safeDuration * newProgress)
                    scheduleHideControls()  // 重置自动隐藏计时
                }
        )
    }
}
