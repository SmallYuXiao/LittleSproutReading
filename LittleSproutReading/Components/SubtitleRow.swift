//
//  SubtitleRow.swift
//  LittleSproutReading
//
//  单条字幕组件 - 支持逐字高亮
//

import SwiftUI

struct SubtitleRow: View {
    @State private var showChinese = false  // 控制中文显示
    let subtitle: Subtitle
    let currentTime: Double
    let isCurrentSubtitle: Bool
    let onWordTap: (String, CGRect) -> Void  // 修改：传递单词位置
    let onSubtitleTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧绿色进度条
            GeometryReader { geometry in
                VStack {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 3, height: progressHeight(in: geometry.size.height))
                    Spacer(minLength: 0)
                }
            }
            .frame(width: 3)
            
            // 字幕内容
            VStack(alignment: .leading, spacing: 6) {
                // 时间戳
                Text("\(subtitle.index) - \(formatTime(subtitle.startTime))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 英文字幕在上 - 逐字高亮
                    if !subtitle.englishText.isEmpty {
                        englishTextView
                            .font(.body)
                    }
                    
                    // 中文字幕在下（点击显示）
                    if !subtitle.chineseText.isEmpty {
                        ZStack(alignment: .leading) {
                            // 中文文本
                            Text(subtitle.chineseText)
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 4)
                            
                            // 磨砂遮罩层（未点击时显示）
                            if !showChinese {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showChinese.toggle()
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isCurrentSubtitle ? Color.green.opacity(0.1) : Color.clear)
        .overlay(
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundColor(Color.gray.opacity(0.2))
                .padding(.horizontal, 16),
            alignment: .bottom
        )
        .contentShape(Rectangle())  // 确保整个区域都可点击
        .onTapGesture {
            onSubtitleTap()
        }
    }

    // MARK: - 虚线形状
    struct DashedLine: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            return path
        }
    }
    
    // MARK: - 英文文本视图(句子级别高亮)
    private var englishTextView: some View {
        // 🔍 调试：打印原始文本和分词结果
        if subtitle.index <= 3 {
            print("🖼️ [SubtitleRow #\(subtitle.index)] 原始英文文本: \"\(subtitle.englishText)\"")
            print("   文本长度: \(subtitle.englishText.count) 字符")
        }
        
        // 简化版本:整句高亮,每个单词可点击
        let words = subtitle.englishText.split(separator: " ").map(String.init)
        
        if subtitle.index <= 3 {
            print("   分词结果: \(words.count) 个单词")
            print("   前3个单词: \(words.prefix(3))")
        }
        
        return FlowLayout(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Button(action: {
                    // 清理标点符号
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
                    // 使用 UIKit 方式获取全局位置（更可靠）
                    onWordTap(cleanWord, .zero)  // 暂时传 .zero，稍后优化位置
                }) {
                    Text(word)
                        .font(.body)
                        .foregroundColor(isCurrentSubtitle ? .green : .white)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - FlowLayout (自定义布局,支持单词自动换行)
    struct FlowLayout: Layout {
        var spacing: CGFloat = 4
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(
                in: proposal.replacingUnspecifiedDimensions().width,
                subviews: subviews,
                spacing: spacing
            )
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(
                in: bounds.width,
                subviews: subviews,
                spacing: spacing
            )
            for (index, subview) in subviews.enumerated() {
                subview.place(
                    at: CGPoint(x: bounds.minX + result.frames[index].minX,
                               y: bounds.minY + result.frames[index].minY),
                    proposal: ProposedViewSize(result.frames[index].size)
                )
            }
        }
        
        struct FlowResult {
            var frames: [CGRect] = []
            var size: CGSize = .zero
            
            init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var currentX: CGFloat = 0
                var currentY: CGFloat = 0
                var lineHeight: CGFloat = 0
                
                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if currentX + size.width > maxWidth && currentX > 0 {
                        currentX = 0
                        currentY += lineHeight + spacing
                        lineHeight = 0
                    }
                    
                    frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                    currentX += size.width + spacing
                    lineHeight = max(lineHeight, size.height)
                }
                
                self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 计算进度条高度
    private func progressHeight(in totalHeight: CGFloat) -> CGFloat {
        // 只有当前正在播放的字幕才显示进度条
        guard isCurrentSubtitle else {
            return 0
        }
        
        // 使用高精度计算
        let duration = subtitle.endTime - subtitle.startTime
        guard duration > 0.001 else {  // 避免除以极小的数
            return 0
        }
        
        // 确保时间在有效范围内
        guard currentTime >= subtitle.startTime else {
            return 0
        }
        
        // 如果时间已经超过结束时间，显示完整高度
        guard currentTime <= subtitle.endTime else {
            return totalHeight
        }
        
        // 计算当前进度（使用高精度Double）
        let elapsedTime = currentTime - subtitle.startTime
        let progress = elapsedTime / duration
        
        // 限制进度在 0-100% 之间
        let clampedProgress = max(0.0, min(1.0, progress))
        
        // 🚀 智能加速：当进度超过 90% 时，提前显示为 100%
        // 这样可以确保在字幕切换前，进度条视觉上已经"走完了"
        // 避免"还差一点点就要切换"的情况
        let finalProgress: Double
        if clampedProgress >= 0.90 {
            finalProgress = 1.0  // 提前完成
        } else {
            // 前 90% 按正常速度走，但稍微加速（1.05倍）
            // 这样可以留出缓冲时间
            finalProgress = min(1.0, clampedProgress * 1.05)
        }
        
        // 转换为 CGFloat
        let height = totalHeight * CGFloat(finalProgress)
        
        // 确保返回值有效
        return height.isFinite ? height : 0
    }
    
    /// 格式化时间
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, secs, millis)
    }
}
