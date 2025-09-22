import SwiftUI

// MARK: - 增强的记忆辅助视图
struct EnhancedMemoryAidView: View {
    let word: String
    let etymology: String?
    let memoryTip: String?
    let relatedWords: [String]?
    let appwriteService: AppwriteService
    
    
    var body: some View {
        // 记忆辅助信息
        if etymology != nil || memoryTip != nil || relatedWords != nil {
            VStack(alignment: .leading, spacing: 20) {
                // 主标题
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("记忆辅助")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("帮助您更好地记住单词")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // 分割线
                Rectangle()
                    .fill(.purple.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                
                // 内容区域
                VStack(spacing: 20) {
                    // 记忆技巧 - 放在最前面
                    if let memoryTip = memoryTip, !memoryTip.isEmpty {
                        EnhancedMemoryInfoCard(
                            icon: "lightbulb.fill",
                            title: "记忆技巧",
                            content: memoryTip,
                            color: .yellow,
                            backgroundColor: .yellow.opacity(0.08)
                        )
                    }
                    
                    // 词源信息 - 放在记忆技巧后面
                    if let etymology = etymology, !etymology.isEmpty {
                        EnhancedMemoryInfoCard(
                            icon: "book.closed.fill",
                            title: "词源",
                            content: etymology,
                            color: .orange,
                            backgroundColor: .orange.opacity(0.08)
                        )
                    }
                    
                    // 相关单词
                    if let relatedWords = relatedWords, !relatedWords.isEmpty {
                        EnhancedRelatedWordsCard(
                            icon: "link",
                            title: "相关单词",
                            words: relatedWords,
                            color: .blue,
                            backgroundColor: .blue.opacity(0.08)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .onAppear {
                print("🧠 EnhancedMemoryAidView显示 - 单词: \(word)")
                print("   - etymology: \(etymology ?? "nil")")
                print("   - memoryTip: \(memoryTip ?? "nil")")
                print("   - relatedWords: \(relatedWords ?? [])")
            }
        }
    }
}

// MARK: - 增强的记忆信息卡片
struct EnhancedMemoryInfoCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack(spacing: 12) {
                // 图标背景
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 分割线
            Rectangle()
                .fill(color.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // 内容区域
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - 增强的相关单词卡片
struct EnhancedRelatedWordsCard: View {
    let icon: String
    let title: String
    let words: [String]
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack(spacing: 12) {
                // 图标背景
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // 单词数量标签
                Text("\(words.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(color)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 分割线
            Rectangle()
                .fill(color.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // 单词标签区域
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(words, id: \.self) { word in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(color.opacity(0.2))
                                .frame(width: 6, height: 6)
                            
                            Text(word)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - 记忆信息行（保留旧版本以兼容）
struct MemoryInfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.body)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
    }
}

// MARK: - 增强的社区记忆技巧卡片
struct EnhancedCommunityMemoryTipCard: View {
    let tip: MemoryTip
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack(spacing: 10) {
                Image(systemName: tip.category.icon)
                    .font(.title3)
                    .foregroundStyle(Color(tip.category.color))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tip.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(tip.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    onLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tip.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundStyle(tip.isLikedByCurrentUser ? .red : .gray)
                        
                        Text("\(tip.likeCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // 内容
            Text(tip.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 社区记忆技巧行（保留旧版本以兼容）
struct CommunityMemoryTipRow: View {
    let tip: MemoryTip
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: tip.category.icon)
                    .foregroundStyle(Color(tip.category.color))
                    .font(.caption)
                
                Text(tip.authorName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    onLike()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: tip.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(tip.isLikedByCurrentUser ? .red : .gray)
                        
                        Text("\(tip.likeCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text(tip.content)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .padding(8)
        .background(.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    EnhancedMemoryAidView(
        word: "apple",
        etymology: "来自古英语 æppel，意为果实",
        memoryTip: "想象一个红色的苹果，A-P-P-L-E",
        relatedWords: ["fruit", "red", "tree"],
        appwriteService: AppwriteService()
    )
    .padding()
}
