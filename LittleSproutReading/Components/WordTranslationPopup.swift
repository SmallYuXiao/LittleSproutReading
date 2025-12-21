//
//  WordTranslationPopup.swift
//  LittleSproutReading
//
//  单词翻译弹窗
//

import SwiftUI

struct WordTranslationPopup: View {
    let word: String
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var definition: WordDefinition?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // 翻译卡片
            VStack(alignment: .leading, spacing: 16) {
                // 标题栏
                HStack {
                    Text(word)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // 发音按钮
                    Button(action: {
                        dictionaryService.pronounce(word)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.blue)
                    }
                    
                    // 收藏按钮
                    Button(action: {
                        dictionaryService.toggleFavorite(word)
                        definition?.isFavorite.toggle()
                    }) {
                        Image(systemName: definition?.isFavorite == true ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    
                    // 关闭按钮
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // 内容区域
                if isLoading {
                    ProgressView("查询中...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if let def = definition {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // 音标
                            if let phonetic = def.phonetic {
                                Text(phonetic)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // 释义列表
                            ForEach(def.definitions.indices, id: \.self) { index in
                                let definition = def.definitions[index]
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(definition.partOfSpeech)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    ForEach(definition.meanings.indices, id: \.self) { meaningIndex in
                                        Text("• \(definition.meanings[meaningIndex])")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                // 查看更多按钮
                if definition != nil {
                    Button(action: {
                        // TODO: 跳转到详细页面
                    }) {
                        HStack {
                            Text("更多")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(20)
            .frame(width: 350)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
        .task {
            await loadDefinition()
        }
    }
    
    // MARK: - 加载释义
    private func loadDefinition() async {
        isLoading = true
        errorMessage = nil
        
        do {
            definition = try await dictionaryService.lookupWord(word)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
