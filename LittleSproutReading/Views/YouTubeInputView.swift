//
//  YouTubeInputView.swift
//  LittleSproutReading
//
//  YouTube URL 输入视图
//

import SwiftUI

struct YouTubeInputView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @State private var urlInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isInitializing = true  // 首次加载状态
    
    init(viewModel: VideoPlayerViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 主内容
            VStack(spacing: 16) {
                Spacer()
                
                // 卡片容器
                VStack(spacing: 32) {
                    // Logo 和标题
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("Little Sprout Reading")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("YouTube 视频学习助手")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 输入区域
                    VStack(spacing: 20) {
                        // URL 输入框
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                            
                            TextField("输入 YouTube URL 或视频 ID", text: $urlInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onSubmit {
                                    loadVideo()
                                }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 加载按钮
                        Button(action: loadVideo) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("开始学习")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(urlInput.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(urlInput.isEmpty || isLoading)
                        .opacity(urlInput.isEmpty ? 0.5 : 1.0)
                        
                        // 错误提示
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // 历史记录（延迟加载）
                    if !isInitializing && !viewModel.historyManager.histories.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("📜 历史记录")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        viewModel.historyManager.clearAll()
                                    }
                                }) {
                                    Text("清空")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.historyManager.histories, id: \.id) { history in
                                        HistoryCard(
                                            history: history,
                                            timeAgo: viewModel.historyManager.timeAgo(from: history.watchedAt),
                                            onTap: {
                                                loadVideoFromHistory(history)
                                            },
                                            onDelete: {
                                                withAnimation {
                                                    viewModel.historyManager.deleteHistory(history)
                                                }
                                            }
                                        )
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                }
                .padding(0)
                .frame(maxWidth: min(600, UIScreen.main.bounds.width - 40))
                // .background(Color.white.opacity(0.05))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Spacer()
                
                // 底部提示
                Text("支持自动字幕提取和逐句学习")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            
            // 延迟加载非关键元素（历史记录和示例）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInitializing = false
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func exampleRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Actions
    
    private func loadVideo() {
        guard !urlInput.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 提取视频 ID
        guard let videoID = YouTubeURLParser.extractVideoID(from: urlInput) else {
            errorMessage = "无效的 YouTube URL 或视频 ID"
            isLoading = false
            return
        }
        
        // 创建 Video 对象
        let video = Video(youtubeVideoID: videoID, title: "YouTube Video")
        
        // 加载视频，传递用户输入的原始 URL
        viewModel.loadVideo(video, originalURL: urlInput)
        
        // 延迟一下再停止加载状态，让用户看到反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    private func loadVideoFromHistory(_ history: VideoHistory) {
        urlInput = history.originalURL
        loadVideo()
    }
}

#Preview {
    YouTubeInputView(viewModel: VideoPlayerViewModel())
        .background(Color.black)
}
