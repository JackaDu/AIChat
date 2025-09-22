import Foundation

// MARK: - 单词数据管理器
class WordDataManager: ObservableObject {
    @Published var loadProgress: Double = 0.0
    @Published var isLoading = false
    
    private let appwriteDatabaseManager: AppwriteDatabaseManager
    
    init(appwriteService: AppwriteService) {
        self.appwriteDatabaseManager = AppwriteDatabaseManager(appwriteService: appwriteService)
    }
    
    // 初始化数据库（如果需要）
    func initializeDatabase() async throws {
        try await appwriteDatabaseManager.createDatabaseAndCollection()
    }
    
    // 从数据库加载单词
    func loadWordsFromDatabase(grade: Grade, textbook: String, unit: String) async throws -> [StudyWord] {
        await MainActor.run {
            isLoading = true
            loadProgress = 0.0
        }
        
        do {
            print("🗄️ 从Appwrite数据库加载单词...")
            print("- 年级: \(grade)")
            print("- 教材: \(textbook)")
            print("- 单元: \(unit)")
            
            // 从数据库加载StudyWord
            let studyWords = try await appwriteDatabaseManager.loadStudyWords(
                grade: grade,
                textbook: textbook,
                unit: unit,
                limit: 10000
            )
            
            await MainActor.run {
                loadProgress = 1.0
                isLoading = false
                print("✅ 成功从数据库加载 \(studyWords.count) 个StudyWord")
            }
            
            return studyWords
            
        } catch {
            print("⚠️ 数据库加载失败: \(error.localizedDescription)")
            
            await MainActor.run {
                loadProgress = 1.0
                isLoading = false
            }
            
            throw error
        }
    }
}
