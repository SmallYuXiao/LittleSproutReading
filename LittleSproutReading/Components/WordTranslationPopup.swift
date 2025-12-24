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
        let screenSize = UIScreen.main.bounds.size
        let layout = popupLayout(in: screenSize)
        
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    closePopup()
                }
            
            // 翻译卡片（带箭头） - 使用自定义气泡形状，箭头精确指向单词
            PopupBubbleShape(
                arrowX: layout.arrowX,
                arrowSize: layout.arrowSize,
                cornerRadius: 12
            )
            .fill(
                LinearGradient(
                    colors: [Color.green.opacity(0.95), Color.green.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: layout.popupWidth, height: layout.popupHeight + layout.arrowSize.height)
            .overlay(
                cardContent
                    .padding(.bottom, layout.arrowSize.height) // 留出箭头空间
            , alignment: .top)
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
            .position(layout.position)
        }
        .onAppear {
            // 弹窗出现时暂停播放
            wasPlaying = viewModel.isPlaying
            if wasPlaying {
                viewModel.player?.pause()
                viewModel.isPlaying = false
            }
            
            // 自动播放单词发音
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dictionaryService.pronounce(word)
            }
        }
        .task {
            await loadDefinition()
        }
    }
    
    // MARK: - 布局计算（位置 + 箭头精确对齐）
    private func popupLayout(in screenSize: CGSize) -> (position: CGPoint, arrowX: CGFloat, popupWidth: CGFloat, popupHeight: CGFloat, arrowSize: CGSize) {
        let popupWidth: CGFloat = 260
        let popupHeight: CGFloat = 140
        let arrowSize = CGSize(width: 16, height: 10)
        let margin: CGFloat = 12      // 水平安全边距（缩小，让箭头更贴近单词）
        let gap: CGFloat = 6          // 弹窗与单词的竖直间距
        let wordCenterX = wordPosition.midX
        let targetY = wordPosition.midY   // 以单词区域的垂直中心为指向点
        
        // 计算弹窗中心 X，确保不出屏幕
        let popupCenterX = min(max(wordCenterX, popupWidth / 2 + margin),
                               screenSize.width - popupWidth / 2 - margin)
        
        // 箭头相对弹窗的 X（从左边缘算起）
        let popupLeft = popupCenterX - popupWidth / 2
        let rawArrowX = wordCenterX - popupLeft
        let arrowX = min(max(rawArrowX, arrowSize.width / 2 + margin),
                         popupWidth - arrowSize.width / 2 - margin)
        
        // 计算弹窗中心 Y：箭头尖端需要指向目标点（单词垂直中心附近）
        // 弹窗中心 = 目标点 - gap - 箭头高 - 弹窗高度一半，再整体上移 60px
        let popupCenterY = targetY - gap - arrowSize.height - popupHeight / 2 - 60
        let minY = popupHeight / 2 + 50  // 顶部安全值
        
        return (
            position: CGPoint(x: popupCenterX, y: max(minY, popupCenterY)),
            arrowX: arrowX,
            popupWidth: popupWidth,
            popupHeight: popupHeight,
            arrowSize: arrowSize
        )
    }
    
    // MARK: - 卡片内容（固定高度，极简版）
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏（单词 + 发音 + 收藏 + 关闭）
            HStack(alignment: .center, spacing: 8) {
                // 单词
                Text(word)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // 发音按钮
                Button(action: {
                    dictionaryService.pronounce(word)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 收藏按钮
                Button(action: {
                    dictionaryService.toggleFavorite(word)
                }) {
                    Image(systemName: dictionaryService.favorites.contains(word.lowercased()) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                
                // 关闭按钮
                Button(action: {
                    closePopup()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 内容区域（固定高度）
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("查询中...")
                            .tint(.white)
                            .font(.caption)
                        Spacer()
                    }
                    .frame(height: 80)
                } else if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(height: 80)
                } else if let def = definition {
                    // 中文翻译（大号显示）
                    if !def.chineseTranslation.isEmpty {
                        Text(def.chineseTranslation)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    
                    // 例句（只显示1个）
                    if let firstExample = def.examples.first {
                        HStack(alignment: .top, spacing: 8) {
                            // 播放按钮
                            Button(action: {
                                speakExample(firstExample)
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 例句文本
                            Text(firstExample)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                    }
                }
            }
            .frame(height: 80, alignment: .top)  // 固定内容高度
        }
        .padding(12)
        .frame(width: 260, height: 140)  // 固定弹窗尺寸
    }
    
    // MARK: - Helper Methods
    
    private func closePopup() {
        isPresented = false
        
        // 弹窗关闭时恢复播放
        if wasPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.player?.play()
                viewModel.isPlaying = true
            }
        }
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

// MARK: - 带箭头的气泡形状
struct PopupBubbleShape: Shape {
    let arrowX: CGFloat          // 箭头尖端相对弹窗左边缘的 X
    let arrowSize: CGSize        // 箭头尺寸
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let bubbleHeight = rect.height - arrowSize.height
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: bubbleHeight)
        
        // 圆角半径限制，避免过大
        let r = min(cornerRadius, min(bubbleRect.width, bubbleRect.height) / 2)
        
        // 箭头位置限制在有效范围内
        let halfArrowW = arrowSize.width / 2
        let clampedArrowX = min(max(arrowX, halfArrowW + r), bubbleRect.maxX - halfArrowW - r)
        let arrowTip = CGPoint(x: clampedArrowX, y: bubbleRect.maxY + arrowSize.height)
        let arrowLeft = CGPoint(x: clampedArrowX - halfArrowW, y: bubbleRect.maxY)
        let arrowRight = CGPoint(x: clampedArrowX + halfArrowW, y: bubbleRect.maxY)
        
        var path = Path()
        
        // 从左上开始，顺时针绘制
        path.move(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY))
        path.addLine(to: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY))
        path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY + r),
                          control: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY))
        
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - r))
        path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.maxY),
                          control: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY))
        
        // 底部边，插入箭头
        path.addLine(to: CGPoint(x: arrowRight.x, y: bubbleRect.maxY))
        path.addLine(to: arrowTip)
        path.addLine(to: arrowLeft)
        
        path.addLine(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY))
        path.addQuadCurve(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY - r),
                          control: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY))
        
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + r))
        path.addQuadCurve(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY),
                          control: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY))
        
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


