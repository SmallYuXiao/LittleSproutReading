//
//  SubtitleListView.swift
//  LittleSproutReading
//
//  字幕列表视图
//

import SwiftUI

struct SubtitleListView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @State private var selectedWord: String?
    @State private var wordPosition: CGRect?  // 记录单词的位置
    @State private var showTranslation = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
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
            .background(Color.black)
            .onChange(of: viewModel.currentSubtitleIndex) { newIndex in
                guard let index = newIndex,
                      index < viewModel.subtitles.count else { return }
                
                withAnimation {
                    proxy.scrollTo(viewModel.subtitles[index].id, anchor: .center)
                }
            }
            // 监听播放状态，播放时自动关闭弹窗
            .onChange(of: viewModel.isPlaying) { isPlaying in
                if isPlaying && showTranslation {
                    showTranslation = false
                    print("▶️ [SubtitleList] 播放恢复，自动关闭弹窗")
                }
            }
        }
        .overlay {
            if showTranslation, let word = selectedWord, let position = wordPosition {
                WordTranslationPopup(
                    word: word,
                    wordPosition: position,
                    viewModel: viewModel,
                    isPresented: $showTranslation
                )
            }
        }
    }
}
