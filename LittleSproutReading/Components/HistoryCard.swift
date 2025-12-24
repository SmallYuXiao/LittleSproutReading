//
//  HistoryCard.swift
//  LittleSproutReading
//
//  历史记录卡片组件
//

import SwiftUI

struct HistoryCard: View {
    let history: VideoHistory
    let timeAgo: String
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 视频图标
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            // 视频信息（可点击区域）
            VStack(alignment: .leading, spacing: 4) {
                Text(history.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(timeAgo)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            // 删除按钮
            Button(action: {
                onDelete()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())  // 使用 BorderlessButtonStyle
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HistoryCard(
        history: VideoHistory(
            videoID: "dQw4w9WgXcQ",
            title: "Rick Astley - Never Gonna Give You Up",
            originalURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ),
        timeAgo: "2小时前",
        onTap: {},
        onDelete: {}
    )
    .padding()
    .background(Color.black)
}
