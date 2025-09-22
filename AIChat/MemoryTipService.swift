import Foundation

// MARK: - 记忆技巧服务
@MainActor
class MemoryTipService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let appwriteService: AppwriteService
    private let currentUserId: String
    
    init(appwriteService: AppwriteService) {
        self.appwriteService = appwriteService
        self.currentUserId = appwriteService.currentUser?.id ?? ""
    }
    
    // MARK: - 获取单词的记忆技巧
    func getMemoryTips(for word: String, limit: Int = 10) async -> [MemoryTip] {
        isLoading = true
        errorMessage = nil
        
        do {
            // 这里应该调用Appwrite API获取记忆技巧
            // 暂时返回模拟数据
            let mockTips = createMockMemoryTips(for: word)
            
            isLoading = false
            return mockTips
        } catch {
            errorMessage = "获取记忆技巧失败: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
    
    // MARK: - 创建记忆技巧
    func createMemoryTip(word: String, content: String, category: MemoryTipCategory) async -> MemoryTip? {
        isLoading = true
        errorMessage = nil
        
        do {
            // 这里应该调用Appwrite API创建记忆技巧
            let newTip = MemoryTip(
                word: word,
                content: content,
                authorId: currentUserId,
                authorName: appwriteService.currentUser?.name ?? "匿名用户",
                category: category
            )
            
            // 模拟API调用延迟
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
            
            isLoading = false
            return newTip
        } catch {
            errorMessage = "创建记忆技巧失败: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    // MARK: - 点赞/取消点赞记忆技巧
    func toggleLike(for tip: MemoryTip) async -> MemoryTip? {
        isLoading = true
        errorMessage = nil
        
        do {
            // 这里应该调用Appwrite API切换点赞状态
            let updatedTip = MemoryTip(
                id: tip.id,
                word: tip.word,
                content: tip.content,
                authorId: tip.authorId,
                authorName: tip.authorName,
                category: tip.category,
                createdAt: tip.createdAt,
                likeCount: tip.isLikedByCurrentUser ? tip.likeCount - 1 : tip.likeCount + 1,
                isLikedByCurrentUser: !tip.isLikedByCurrentUser
            )
            
            // 模拟API调用延迟
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            isLoading = false
            return updatedTip
        } catch {
            errorMessage = "点赞操作失败: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    // MARK: - 获取热门记忆技巧
    func getPopularMemoryTips(for word: String, limit: Int = 5) async -> [MemoryTip] {
        isLoading = true
        errorMessage = nil
        
        do {
            // 这里应该调用Appwrite API获取热门记忆技巧
            let allTips = createMockMemoryTips(for: word)
            let popularTips = Array(allTips.sorted { $0.likeCount > $1.likeCount }.prefix(limit))
            
            isLoading = false
            return popularTips
        } catch {
            errorMessage = "获取热门记忆技巧失败: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
    
    // MARK: - 模拟数据（开发阶段使用）
    private func createMockMemoryTips(for word: String) -> [MemoryTip] {
        let mockTips = [
            MemoryTip(
                word: word,
                content: "联想记忆：想象这个单词的发音和中文意思的关联，比如发音听起来像什么中文词汇",
                authorId: "user1",
                authorName: "学习达人小王",
                category: .association,
                createdAt: Date().addingTimeInterval(-86400), // 1天前
                likeCount: 15,
                isLikedByCurrentUser: false
            ),
            MemoryTip(
                word: word,
                content: "词根记忆：分析这个单词的词根和词缀，理解其构成规律",
                authorId: "user2",
                authorName: "英语老师李老师",
                category: .etymology,
                createdAt: Date().addingTimeInterval(-172800), // 2天前
                likeCount: 23,
                isLikedByCurrentUser: true
            ),
            MemoryTip(
                word: word,
                content: "故事记忆：编一个小故事，把这个单词融入其中，让记忆更生动",
                authorId: "user3",
                authorName: "创意学习者",
                category: .story,
                createdAt: Date().addingTimeInterval(-259200), // 3天前
                likeCount: 8,
                isLikedByCurrentUser: false
            ),
            MemoryTip(
                word: word,
                content: "视觉记忆：画一个简单的图，把单词的意思用图像表现出来",
                authorId: "user4",
                authorName: "美术爱好者",
                category: .visual,
                createdAt: Date().addingTimeInterval(-345600), // 4天前
                likeCount: 12,
                isLikedByCurrentUser: false
            )
        ]
        
        return mockTips
    }
}
