import Foundation

// MARK: - 单词分析数据模型
struct WordAnalysis: Codable {
    let etymology: String           // 词源助记
    let root: String               // 词根
    let prefix: String             // 前缀
    let suffix: String             // 后缀
    
    // 语法变形
    let plural: String             // 复数形式
    let pastTense: String          // 过去式
    let presentParticiple: String  // 现在分词
    let pastParticiple: String     // 过去分词
    let gerund: String             // 动名词
    
    // 例句
    let examExamples: [ExamExample]        // 高考真题例句
    let practicalExamples: [PracticalExample] // 实用例句
    let grammarUsage: [String]              // 语法用法说明
    
    // 相关词汇
    let relatedWords: [String]     // 相关词汇
}

struct ExamExample: Codable {
    let year: String               // 年份
    let province: String           // 省份
    let sentence: String           // 英文例句
    let translation: String        // 中文翻译
}

struct PracticalExample: Codable {
    let category: String           // 例句类别
    let sentence: String           // 英文例句
    let translation: String        // 中文翻译
}

// MARK: - 单词分析服务
@MainActor
class WordAnalysisService: ObservableObject {
    private let openAIKey = AppConfig.shared.openAIAPIKey
    
    func analyzeWord(
        _ word: String,
        meaning: String? = nil,
        phonetic: String? = nil,
        textbook: String? = nil,
        coursebook: String? = nil,
        unit: String? = nil
    ) async throws -> WordAnalysis {
        // 构建提示词
        var prompt = """
        请分析英文单词 "\(word)" 并提供以下信息：
        """
        
        // 添加教材信息
        if let textbook = textbook, let coursebook = coursebook, let unit = unit {
            prompt += """
            
            教材信息：
            - 教材：\(textbook)
            - 课本：\(coursebook)
            - 单元：Unit \(unit)
            """
        }
        
        if let meaning = meaning {
            prompt += "\n- 中文含义：\(meaning)"
        }
        
        if let phonetic = phonetic {
            prompt += "\n- 音标：\(phonetic)"
        }
        
        prompt += """
        
        请提供以下详细信息：
        1. 词源助记：提供词根、前缀、后缀的详细分析，帮助记忆
        2. 语法变形：包括单复数、时态变化等
        3. 高考真题例句：提供最近几年的高考真题中的例句（如果有的话）
        4. 实用例句：提供日常生活中的实用例句
        5. 语法用法：说明该词的常见语法用法
        6. 相关词汇：提供相关的同义词、反义词或词族
        
        请以JSON格式返回，格式如下：
        {
            "etymology": "词源助记",
            "root": "词根",
            "prefix": "前缀",
            "suffix": "后缀",
            "plural": "复数形式",
            "pastTense": "过去式",
            "presentParticiple": "现在分词",
            "pastParticiple": "过去分词",
            "gerund": "动名词",
            "examExamples": [
                {
                    "year": "年份",
                    "province": "省份",
                    "sentence": "英文例句",
                    "translation": "中文翻译"
                }
            ],
            "practicalExamples": [
                {
                    "category": "例句类别",
                    "sentence": "英文例句",
                    "translation": "中文翻译"
                }
            ],
            "grammarUsage": ["语法用法1", "语法用法2"],
            "relatedWords": ["相关词1", "相关词2"]
        }
        """
        
        // 打印prompt
        print("=== 单词分析Prompt ===")
        print(prompt)
        print("========================")
        
        // 调用OpenAI API
        let analysis = try await callOpenAI(prompt: prompt)
        
        // 解析返回的JSON
        return try parseWordAnalysis(analysis)
    }
    
    private func callOpenAI(prompt: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw WordAnalysisError.invalidURL
        }
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                Message(role: "system", content: "你是一个专业的英语词汇分析专家，专门分析单词的词根、语法变形和提供例句。"),
                Message(role: "user", content: prompt)
            ],
            temperature: 0.3,
            max_tokens: 2000
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WordAnalysisError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw WordAnalysisError.noContent
        }
        
        return content
    }
    
    private func parseWordAnalysis(_ jsonString: String) throws -> WordAnalysis {
        // 清理JSON字符串，移除可能的markdown标记
        let cleanJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            throw WordAnalysisError.parsingError
        }
        
        let decoder = JSONDecoder()
        let analysis = try decoder.decode(WordAnalysis.self, from: data)
        
        return analysis
    }
}

// MARK: - OpenAI API 模型
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

struct Message: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

// MARK: - 错误类型
enum WordAnalysisError: Error, LocalizedError {
    case invalidURL
    case apiError
    case noContent
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .apiError:
            return "API调用失败"
        case .noContent:
            return "没有返回内容"
        case .parsingError:
            return "解析失败"
        }
    }
}

// MARK: - 模拟数据（用于测试）
extension WordAnalysisService {
    func getMockAnalysis(for word: String) -> WordAnalysis {
        return WordAnalysis(
            etymology: "来自拉丁语 'penicillus'，意为'小尾巴'，因为早期的笔像小尾巴一样",
            root: "penicillus",
            prefix: "",
            suffix: "-il (表示'小'的后缀)",
            plural: "pencils",
            pastTense: "",
            presentParticiple: "",
            pastParticiple: "",
            gerund: "",
            examExamples: [
                ExamExample(
                    year: "2023",
                    province: "全国卷",
                    sentence: "The teacher asked us to write with a pencil.",
                    translation: "老师要求我们用铅笔写字。"
                ),
                ExamExample(
                    year: "2022",
                    province: "北京卷",
                    sentence: "Can you lend me a pencil?",
                    translation: "你能借我一支铅笔吗？"
                )
            ],
            practicalExamples: [
                PracticalExample(
                    category: "日常对话",
                    sentence: "I need to sharpen my pencil.",
                    translation: "我需要削铅笔。"
                ),
                PracticalExample(
                    category: "学习场景",
                    sentence: "The pencil is on the desk.",
                    translation: "铅笔在桌子上。"
                )
            ],
            grammarUsage: [
                "作为可数名词使用",
                "可以用 'a' 或 'the' 修饰",
                "复数形式为 pencils"
            ],
            relatedWords: ["pen", "paper", "eraser", "sharpener"]
        )
    }
}
