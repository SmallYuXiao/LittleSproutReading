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
                
                // 横屏模式切换按钮（右上角）
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                forceLandscape.toggle()
                            }
                        }) {
                            Image(systemName: "rotate.right")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(16)
                    }
                    Spacer()
                }
            }
            
            // 播放控制条（浮动在底部）
            controlsView
                .padding()
                .background(Color.black.opacity(0.8))
        }
    }
    
    // MARK: - 播放控制
    private var controlsView: some View {
        VStack(spacing: 12) {
            // 进度条
            let safeDuration = viewModel.duration.isFinite && viewModel.duration > 0 ? viewModel.duration : 1.0
            let safeCurrentTime = min(max(viewModel.currentTime, 0), safeDuration)
            
            Slider(
                value: Binding(
                    get: { safeCurrentTime },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...safeDuration
            )
            .tint(.green)
            
            // 时间显示
            HStack {
                Text(viewModel.formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 街溜子模式按钮
                Button(action: {
                    viewModel.toggleStreetWandererMode()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isStreetWandererMode ? "person.wave.2.fill" : "person.wave.2")
                        Text("街溜子模式")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.isStreetWandererMode ? .green : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(viewModel.isStreetWandererMode ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(viewModel.formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}
