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
    @State private var showTranslation = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.subtitles) { subtitle in
                        SubtitleRow(
                            subtitle: subtitle,
                            currentTime: viewModel.currentTime,  // 简化:不需要逐字时间
                            isCurrentSubtitle: viewModel.currentSubtitleIndex == subtitle.index - 1,
                            onWordTap: { word in
                                selectedWord = word
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
        }
        .overlay {
            if showTranslation, let word = selectedWord {
                WordTranslationPopup(word: word, isPresented: $showTranslation)
            }
        }
    }
}
