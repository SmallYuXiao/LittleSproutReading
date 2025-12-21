//
//  SubtitleRow.swift
//  LittleSproutReading
//
//  单条字幕组件 - 支持逐字高亮
//

import SwiftUI

struct SubtitleRow: View {
    let subtitle: Subtitle
    let currentTime: Double
    let isCurrentSubtitle: Bool
    let onWordTap: (String) -> Void
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
                    
                    // 中文字幕在下
                    if !subtitle.chineseText.isEmpty {
                        Text(subtitle.chineseText)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .background(isCurrentSubtitle ? Color.green.opacity(0.1) : Color.clear)
        .onTapGesture {
            onSubtitleTap()
        }
    }
    
    // MARK: - 英文文本视图(句子级别高亮)
    private var englishTextView: some View {
        // 简化版本:整句高亮,每个单词可点击
        let words = subtitle.englishText.split(separator: " ").map(String.init)
        
        return FlowLayout(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Button(action: {
                    // 清理标点符号
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
                    onWordTap(cleanWord)
                }) {
                    Text(word)
                        .font(.body)
                        .foregroundColor(isCurrentSubtitle ? .green : .white)  // 整句高亮
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
        // 只有当前字幕才显示进度条
        guard isCurrentSubtitle else {
            return 0
        }
        
        // 确保时间在字幕范围内
        guard currentTime >= subtitle.startTime && currentTime <= subtitle.endTime else {
            return 0
        }
        
        let duration = subtitle.endTime - subtitle.startTime
        guard duration > 0 else {
            return 0
        }
        
        let progress = (currentTime - subtitle.startTime) / duration
        let clampedProgress = max(0, min(1, progress))  // 限制在0-1之间
        return totalHeight * CGFloat(clampedProgress)
    }
    
    /// 格式化时间
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, secs, millis)
    }
}
