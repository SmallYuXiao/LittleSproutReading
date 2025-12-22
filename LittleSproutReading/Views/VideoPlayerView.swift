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
    
    var body: some View {
        VStack(spacing: 0) {
            // 视频播放器
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
            }
            
            // 播放控制条
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
            
            // 控制按钮
            HStack {
                // 时间显示
                Text(viewModel.formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 字幕偏移调节
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.adjustSubtitleOffset(by: -0.5)
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.white)
                    }
                    
                    Text(String(format: "字幕: %.1fs", viewModel.subtitleOffset))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(width: 70)
                    
                    Button(action: {
                        viewModel.adjustSubtitleOffset(by: 0.5)
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // 播放/暂停按钮
                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 总时长
                Text(viewModel.formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}
