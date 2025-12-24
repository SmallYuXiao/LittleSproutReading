//
//  SubtitleListView.swift
//  LittleSproutReading
//
//  字幕列表视图
//

import SwiftUI

struct SubtitleListView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Binding var selectedWord: String?
    @Binding var wordPosition: CGRect?
    @Binding var showTranslation: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.subtitles.isEmpty {
                    // 无字幕提示
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "text.bubble")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        if let error = viewModel.subtitleError {
                            Text(error)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        } else {
                            Text("该视频暂无字幕")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.subtitles) { subtitle in
                            SubtitleRow(
                                subtitle: subtitle,
                                currentTime: viewModel.currentTime,
                                isCurrentSubtitle: viewModel.currentSubtitleIndex == subtitle.index - 1,
                                onWordTap: { word, frame in
                                    selectedWord = word
                                    wordPosition = frame
                                    showTranslation = true
                                },
                                onSubtitleTap: {
                                    viewModel.seekToSubtitle(subtitle)
                                }
                            )
                            .id(subtitle.id)
                        }
                    }
                }
            }
            .background(Color.black)
            .onChange(of: viewModel.currentSubtitleIndex) { newIndex in
                guard let index = newIndex,
                      index < viewModel.subtitles.count else { return }
                
                withAnimation {
                    proxy.scrollTo(viewModel.subtitles[index].id, anchor: .center)
                }
            }
            // 监听播放状态,播放时自动关闭弹窗
            .onChange(of: viewModel.isPlaying) { isPlaying in
                if isPlaying && showTranslation {
                    showTranslation = false
                }
            }
        }
    }
}
