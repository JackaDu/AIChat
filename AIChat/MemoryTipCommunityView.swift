import SwiftUI

// MARK: - 记忆技巧社区视图
struct MemoryTipCommunityView: View {
    let word: String
    @StateObject private var memoryTipService: MemoryTipService
    @State private var tips: [MemoryTip] = []
    @State private var showingCreateTip = false
    @State private var selectedCategory: MemoryTipCategory = .general
    
    init(word: String, appwriteService: AppwriteService) {
        self.word = word
        self._memoryTipService = StateObject(wrappedValue: MemoryTipService(appwriteService: appwriteService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部信息
                VStack(spacing: 8) {
                    Text("单词: \(word)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("社区记忆技巧")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                if memoryTipService.isLoading {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                } else if tips.isEmpty {
                    // 空状态
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                        
                        Text("还没有记忆技巧")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("成为第一个分享记忆技巧的人吧！")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    // 技巧列表
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tips) { tip in
                                MemoryTipCard(tip: tip, onLike: {
                                    Task {
                                        if let updatedTip = await memoryTipService.toggleLike(for: tip) {
                                            if let index = tips.firstIndex(where: { $0.id == tip.id }) {
                                                tips[index] = updatedTip
                                            }
                                        }
                                    }
                                })
                            }
                        }
                        .padding()
                    }
                }
                
                // 底部创建按钮
                Button {
                    showingCreateTip = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("分享我的记忆技巧")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("记忆技巧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        // 关闭视图的逻辑
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTip) {
            CreateMemoryTipView(word: word, memoryTipService: memoryTipService) { newTip in
                tips.insert(newTip, at: 0)
            }
        }
        .onAppear {
            Task {
                tips = await memoryTipService.getMemoryTips(for: word)
            }
        }
    }
}

// MARK: - 记忆技巧卡片
struct MemoryTipCard: View {
    let tip: MemoryTip
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息
            HStack {
                // 分类图标
                Image(systemName: tip.category.icon)
                    .foregroundStyle(Color(tip.category.color))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(tip.authorName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // 时间
                Text(timeAgoString(from: tip.createdAt))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            
            // 内容
            Text(tip.content)
                .font(.title3)
                .foregroundStyle(.primary)
                .lineLimit(nil)
            
            // 底部操作
            HStack {
                // 点赞按钮
                Button {
                    onLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tip.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundStyle(tip.isLikedByCurrentUser ? .red : .gray)
                        
                        Text("\(tip.likeCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)天前"
        }
    }
}

// MARK: - 创建记忆技巧视图
struct CreateMemoryTipView: View {
    let word: String
    let memoryTipService: MemoryTipService
    let onTipCreated: (MemoryTip) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedCategory: MemoryTipCategory = .general
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 单词信息
                VStack(spacing: 8) {
                    Text("为单词创建记忆技巧")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(word)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 分类选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择分类")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(MemoryTipCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(category.color))
                                    
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(selectedCategory == category ? .blue.opacity(0.1) : .gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                // 内容输入
                VStack(alignment: .leading, spacing: 12) {
                    Text("记忆技巧内容")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .padding()
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("创建记忆技巧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") {
                        Task {
                            if let newTip = await memoryTipService.createMemoryTip(
                                word: word,
                                content: content,
                                category: selectedCategory
                            ) {
                                onTipCreated(newTip)
                                dismiss()
                            }
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    MemoryTipCommunityView(word: "apple", appwriteService: AppwriteService())
}
