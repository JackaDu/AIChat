import Foundation

// MARK: - 记忆技巧数据模型
struct MemoryTip: Codable, Identifiable {
    let id: String
    let word: String
    let content: String
    let authorId: String
    let authorName: String
    let createdAt: Date
    let likeCount: Int
    let isLikedByCurrentUser: Bool
    let category: MemoryTipCategory
    
    init(
        id: String = UUID().uuidString,
        word: String,
        content: String,
        authorId: String,
        authorName: String,
        category: MemoryTipCategory = .general,
        createdAt: Date = Date(),
        likeCount: Int = 0,
        isLikedByCurrentUser: Bool = false
    ) {
        self.id = id
        self.word = word
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.category = category
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
    }
}

// MARK: - 记忆技巧分类
enum MemoryTipCategory: String, CaseIterable, Codable {
    case etymology = "词源记忆"
    case visual = "视觉记忆"
    case association = "联想记忆"
    case story = "故事记忆"
    case pronunciation = "发音记忆"
    case general = "通用技巧"
    
    var icon: String {
        switch self {
        case .etymology:
            return "book.fill"
        case .visual:
            return "eye.fill"
        case .association:
            return "brain.head.profile"
        case .story:
            return "book.pages.fill"
        case .pronunciation:
            return "speaker.wave.2.fill"
        case .general:
            return "lightbulb.fill"
        }
    }
    
    var color: String {
        switch self {
        case .etymology:
            return "orange"
        case .visual:
            return "blue"
        case .association:
            return "purple"
        case .story:
            return "green"
        case .pronunciation:
            return "red"
        case .general:
            return "yellow"
        }
    }
}

// MARK: - 点赞记录
struct MemoryTipLike: Codable {
    let id: String
    let tipId: String
    let userId: String
    let createdAt: Date
    
    init(tipId: String, userId: String) {
        self.id = UUID().uuidString
        self.tipId = tipId
        self.userId = userId
        self.createdAt = Date()
    }
}

// MARK: - 记忆技巧创建请求
struct CreateMemoryTipRequest: Codable {
    let word: String
    let content: String
    let category: MemoryTipCategory
}

// MARK: - 记忆技巧响应
struct MemoryTipResponse: Codable {
    let tips: [MemoryTip]
    let totalCount: Int
    let hasMore: Bool
}
