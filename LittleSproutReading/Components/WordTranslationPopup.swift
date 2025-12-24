//
//  WordTranslationPopup.swift
//  LittleSproutReading
//
//  单词翻译弹窗
//

import SwiftUI

struct WordTranslationPopup: View {
    let word: String
    let wordPosition: CGRect  // 单词的位置
    let viewModel: VideoPlayerViewModel
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var definition: WordDefinition?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Binding var isPresented: Bool
    @State private var wasPlaying = false  // 记录弹窗前的播放状态
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明背景
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closePopup()
                    }
                
                // 翻译卡片（带箭头）
                VStack(spacing: 0) {
                    // 卡片内容
                    cardContent
                    
                    // 向下的箭头（指向单词）
                    HStack {
                        Spacer()
                            .frame(width: arrowOffset(in: geometry.size))
                        Triangle()
                            .fill(Color.green)
                            .frame(width: 16, height: 10)
                            .rotationEffect(.degrees(180))
                            .offset(y: -1)
                        Spacer()
                    }
                    .frame(width: 260)
                }
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
                .position(popupPosition(in: geometry.size))
            }
        }
        .onAppear {
            // 弹窗出现时暂停播放
            wasPlaying = viewModel.isPlaying
            if wasPlaying {
                viewModel.player?.pause()
                viewModel.isPlaying = false
                print("⏸️ [Popup] 暂停播放")
            }
        }
        .task {
            await loadDefinition()
        }
    }
    
    // MARK: - 计算弹窗位置
    private func popupPosition(in screenSize: CGSize) -> CGPoint {
        let popupWidth: CGFloat = 260  // 弹窗宽度
        let popupHeight: CGFloat = 200  // 弹窗预估高度
        
        // 单词中心点
        let wordCenterX = wordPosition.midX
        let wordY = wordPosition.minY
        
        // 计算弹窗 X 位置（居中对齐单词，但不超出屏幕）
        var popupX = wordCenterX
        popupX = max(popupWidth / 2 + 20, popupX)  // 左边界
        popupX = min(screenSize.width - popupWidth / 2 - 20, popupX)  // 右边界
        
        // 计算弹窗 Y 位置（显示在单词上方）
        let popupY = wordY - popupHeight / 2 - 20
        
        return CGPoint(x: popupX, y: max(popupHeight / 2 + 50, popupY))
    }
    
    // MARK: - 计算箭头偏移量（让箭头精确指向单词）
    private func arrowOffset(in screenSize: CGSize) -> CGFloat {
        let popupWidth: CGFloat = 260
        let wordCenterX = wordPosition.midX
        
        // 计算弹窗中心
        var popupCenterX = wordCenterX
        popupCenterX = max(popupWidth / 2 + 20, popupCenterX)
        popupCenterX = min(screenSize.width - popupWidth / 2 - 20, popupCenterX)
        
        // 箭头偏移 = 单词中心 - 弹窗中心
        let offset = wordCenterX - popupCenterX + popupWidth / 2
        
        // 限制箭头在弹窗内（留20px边距）
        return max(20, min(popupWidth - 20, offset))
    }
    
    // MARK: - 卡片内容（极简版）
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题栏
            HStack {
                Text(word)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    closePopup()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 16))
                }
                .buttonStyle(PopupButtonStyle())
            }
                
            // 内容区域
            if isLoading {
                ProgressView("查询中...")
                    .tint(.white)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 8)
            } else if let def = definition {
                VStack(alignment: .leading, spacing: 10) {
                    // 主要翻译（只显示第一个词性的第一个释义）
                    if let firstDef = def.definitions.first,
                       let firstMeaning = firstDef.meanings.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstDef.partOfSpeech)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(3)
                            
                            Text(firstMeaning)
                                .font(.body)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                    }
                    
                    // 例句（显示2个）
                    if !def.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(def.examples.prefix(2).indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 8) {
                                    // 播放按钮
                                    Button(action: {
                                        speakExample(def.examples[index])
                                    }) {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // 例句文本
                                    Text(def.examples[index])
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.95), Color.green.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func closePopup() {
        isPresented = false
    }
    
    /// 播放例句
    private func speakExample(_ text: String) {
        dictionaryService.pronounce(text)
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

// MARK: - 三角形箭头
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 弹窗按钮样式
struct PopupButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


