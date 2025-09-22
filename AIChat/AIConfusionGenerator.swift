import Foundation

// MARK: - 本地混淆选项生成器
class AIConfusionGenerator: ObservableObject {
    
    init(apiKey: String) {
        // apiKey不再需要，但保留参数以保持接口兼容性
    }
    
    
    // 生成混淆选项
    func generateConfusionOptions(
        for word: String,
        correctAnswer: String,
        learningDirection: LearningDirection,
        textbook: String? = nil,
        coursebook: String? = nil,
        unit: String? = nil,
        phonetic: String? = nil,
        partOfSpeech: String? = nil,
        preGeneratedOptions: [String]? = nil
    ) async throws -> [String] {
        
        // 只使用Excel文件中的预生成选项
        if let preGenerated = preGeneratedOptions, !preGenerated.isEmpty {
            print("使用Excel预生成选项")
            return buildOptionsFromPreGenerated(preGenerated: preGenerated, correctAnswer: correctAnswer)
        }
        
        // 如果没有预生成选项，返回空数组
        print("⚠️ 未找到预生成选项，跳过选项生成")
        return []
    }
    
    // 从预生成选项构建完整的选项列表
    private func buildOptionsFromPreGenerated(preGenerated: [String], correctAnswer: String) -> [String] {
        var allOptions = preGenerated
        
        // 确保正确答案包含在选项中
        if !allOptions.contains(correctAnswer) {
            allOptions.append(correctAnswer)
        }
        
        // 打乱顺序并限制为4个选项
        return Array(allOptions.shuffled().prefix(4))
    }
    
}

