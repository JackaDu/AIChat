import Foundation
import UIKit

// MARK: - 手写识别服务
class HandwritingRecognitionService: ObservableObject {
    static let shared = HandwritingRecognitionService()
    
    private init() {}
    
    // MARK: - 识别手写单词
    func recognizeHandwriting(
        image: UIImage,
        expectedWords: [String],
        completion: @escaping (Result<[HandwritingRecognitionResult], HandwritingRecognitionError>) -> Void
    ) {
        print("🔍 ===== 手写识别开始 =====")
        print("📷 图片信息:")
        print("   - 尺寸: \(image.size.width) x \(image.size.height)")
        print("   - 比例: \(image.scale)")
        print("📝 期望识别的单词: \(expectedWords)")
        print("🤖 使用真实OpenAI GPT-4 Vision API识别")
        
        // 使用真实的OpenAI API
        callRealLLMAPI(
            image: image,
            expectedWords: expectedWords,
            completion: completion
        )
    }
    
    // MARK: - 模拟手写识别（实际项目中应该调用真实的LLM API）
    private func simulateHandwritingRecognition(
        image: UIImage,
        expectedWords: [String]
    ) -> [HandwritingRecognitionResult] {
        print("🤖 开始模拟识别过程...")
        print("📊 模拟识别算法说明:")
        print("   - 按用户书写顺序识别")
        print("   - 85% 概率识别正确")
        print("   - 15% 概率模拟手写错误")
        print("   - 不进行真实图像分析")
        
        var results: [HandwritingRecognitionResult] = []
        
        // 模拟用户可能的书写顺序（20%概率改变顺序）
        var simulatedWritingOrder = expectedWords
        let shouldSimulateOrderChange = Double.random(in: 0...1) < 0.2
        
        if shouldSimulateOrderChange && expectedWords.count > 1 {
            // 随机打乱顺序来模拟用户可能的书写顺序
            simulatedWritingOrder.shuffle()
            print("🔄 模拟用户书写顺序变化:")
            for (index, word) in simulatedWritingOrder.enumerated() {
                print("   \(index + 1). \(word)")
            }
        }
        
        print("📝 用户书写顺序:")
        
        for (writingIndex, writtenWord) in simulatedWritingOrder.enumerated() {
            let recognizedWord = simulateWordRecognition(expectedWord: writtenWord)
            let confidence = Double.random(in: 0.75...0.95)
            
            print("   \(writingIndex + 1). \(recognizedWord) (置信度: \(String(format: "%.2f", confidence)))")
            
            // 找到这个单词在期望列表中的位置
            let expectedIndex = expectedWords.firstIndex(of: writtenWord) ?? writingIndex
            let expectedWord = expectedWords[safe: expectedIndex] ?? writtenWord
            
            // 简单的正确性判断：只看单词内容
            let isCorrect = recognizedWord.lowercased() == expectedWord.lowercased()
            
            print("🔄 匹配结果 \(writingIndex + 1):")
            print("   - 书写位置: \(writingIndex + 1)")
            print("   - 识别单词: '\(recognizedWord)'")
            print("   - 期望单词: '\(expectedWord)'")
            print("   - 内容正确: \(isCorrect ? "✅" : "❌")")
            print("   - 置信度: \(String(format: "%.2f", confidence))")
            
            let result = HandwritingRecognitionResult(
                index: writingIndex,
                expectedWord: expectedWord,
                recognizedWord: recognizedWord,
                isCorrect: isCorrect,
                confidence: confidence,
                boundingBox: CGRect(
                    x: Double.random(in: 0.1...0.3),
                    y: Double(writingIndex) * 0.15 + 0.1,
                    width: Double.random(in: 0.4...0.6),
                    height: 0.1
                ),
                actualPosition: writingIndex,
                isOrderCorrect: true // 不再判断顺序正确性
            )
            
            results.append(result)
        }
        
        let correctCount = results.filter { $0.isCorrect }.count
        print("📈 识别结果统计:")
        print("   - 总单词数: \(results.count)")
        print("   - 正确识别: \(correctCount)")
        print("   - 错误识别: \(results.count - correctCount)")
        print("   - 准确率: \(String(format: "%.1f", Double(correctCount) / Double(results.count) * 100))%")
        print("🔍 ===== 手写识别完成 =====")
        
        return results
    }
    
    // MARK: - 模拟单词识别
    private func simulateWordRecognition(expectedWord: String) -> String {
        // 85% 的概率识别正确
        if Double.random(in: 0...1) < 0.85 {
            return expectedWord
        }
        
        // 15% 的概率识别错误，模拟常见的手写错误
        return generateTypicalHandwritingError(for: expectedWord)
    }
    
    // MARK: - 生成典型的手写错误
    private func generateTypicalHandwritingError(for word: String) -> String {
        let commonErrors: [(String, String)] = [
            // 字母形状相似导致的错误
            ("a", "o"), ("o", "a"),
            ("e", "c"), ("c", "e"),
            ("n", "m"), ("m", "n"),
            ("u", "v"), ("v", "u"),
            ("i", "l"), ("l", "i"),
            ("b", "d"), ("d", "b"),
            ("p", "q"), ("q", "p"),
            ("w", "vv"), ("vv", "w"),
            
            // 大小写混淆
            ("I", "l"), ("l", "I"),
            ("O", "0"), ("0", "O"),
            
            // 连写导致的错误
            ("rn", "m"), ("m", "rn"),
            ("cl", "d"), ("d", "cl"),
        ]
        
        var errorWord = word
        
        // 随机应用1-2个错误
        let errorCount = Int.random(in: 1...2)
        
        for _ in 0..<errorCount {
            let randomError = commonErrors.randomElement()!
            errorWord = errorWord.replacingOccurrences(of: randomError.0, with: randomError.1)
        }
        
        // 如果没有变化，随机改变一个字母
        if errorWord == word && !word.isEmpty {
            let randomIndex = word.index(word.startIndex, offsetBy: Int.random(in: 0..<word.count))
            let randomChar = "abcdefghijklmnopqrstuvwxyz".randomElement()!
            errorWord = String(word.prefix(upTo: randomIndex)) + String(randomChar) + String(word.suffix(from: word.index(after: randomIndex)))
        }
        
        return errorWord
    }
}

// MARK: - 手写识别结果
struct HandwritingRecognitionResult {
    let index: Int
    let expectedWord: String
    let recognizedWord: String
    let isCorrect: Bool
    let confidence: Double
    let boundingBox: CGRect // 在图片中的位置（相对坐标 0-1）
    let actualPosition: Int? // 用户实际书写的位置顺序（从0开始）
    let isOrderCorrect: Bool // 顺序是否正确
}

// MARK: - 手写识别错误
enum HandwritingRecognitionError: Error, LocalizedError {
    case invalidImage
    case networkError(String)
    case apiError(String)
    case processingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片格式无效"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .apiError(let message):
            return "API错误: \(message)"
        case .processingError(let message):
            return "处理错误: \(message)"
        }
    }
}

// MARK: - LLM API 配置
struct LLMAPIConfig {
    static let baseURL = "https://api.openai.com/v1"
    static let model = "gpt-4o"  // 使用最新的GPT-4o模型，支持视觉
    static let maxTokens = 1000
    static let apiKey = "YOUR_OPENAI_API_KEY_HERE" // 请在Config.plist中设置您的OpenAI API密钥
    
    // 手写识别的提示词模板
    static func createPrompt(expectedWords: [String]) -> String {
        return """
        请仔细分析这张图片中的手写英文单词。

        参考单词列表：\(expectedWords.joined(separator: ", "))

        请按照用户在图片中的实际书写顺序识别所有手写单词。请严格按照以下JSON格式返回结果：

        {
            "writtenWords": [
                {
                    "position": 1,
                    "recognizedWord": "实际识别到的单词",
                    "confidence": 0.95,
                    "location": {"x": 0.1, "y": 0.1, "width": 0.3, "height": 0.1}
                }
            ]
        }

        **重要识别要求**：
        1. **按书写顺序识别**：严格按照用户在图片中从上到下、从左到右的实际书写顺序
        2. **位置分析**：分析每个单词在图片中的位置坐标，确定准确的书写顺序
        3. **完整识别**：识别图片中所有可见的手写单词，不遗漏任何内容
        4. **准确转录**：尽可能准确地识别每个单词的拼写，即使拼写可能有错误
        5. **置信度评估**：基于字迹清晰度和识别准确性给出置信度评分
        6. **位置记录**：记录每个单词在图片中的相对位置（0-1坐标系）

        **输出说明**：
        - position: 按书写顺序的位置编号（从1开始）
        - recognizedWord: 识别到的实际单词内容
        - confidence: 识别置信度（0-1之间）
        - location: 单词在图片中的位置信息

        **示例**：
        如果用户按顺序写了 [book, apple, cat]，就按这个顺序返回，不需要与参考列表对比正确性。

        只返回JSON格式的结果，不要添加其他文字说明。
        """
    }
}

// MARK: - 真实LLM API实现
extension HandwritingRecognitionService {
    
    func callRealLLMAPI(
        image: UIImage,
        expectedWords: [String],
        completion: @escaping (Result<[HandwritingRecognitionResult], HandwritingRecognitionError>) -> Void
    ) {
        print("🚀 开始调用OpenAI GPT-4 Vision API...")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 图片转换失败")
            completion(.failure(.invalidImage))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        print("📷 图片已转换为Base64，大小: \(base64Image.count) 字符")
        
        let requestBody: [String: Any] = [
            "model": LLMAPIConfig.model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": LLMAPIConfig.createPrompt(expectedWords: expectedWords)
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": LLMAPIConfig.maxTokens
        ]
        
        guard let url = URL(string: "\(LLMAPIConfig.baseURL)/chat/completions") else {
            print("❌ URL构建失败")
            completion(.failure(.apiError("Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(LLMAPIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📤 API请求已构建，开始发送...")
        } catch {
            print("❌ 请求编码失败: \(error)")
            completion(.failure(.processingError("Failed to encode request")))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 网络请求失败: \(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API响应状态码: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ 未收到响应数据")
                completion(.failure(.networkError("No data received")))
                return
            }
            
            print("📥 收到响应数据，大小: \(data.count) 字节")
            
            do {
                let apiResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("✅ API响应解析成功")
                
                if let errorInfo = apiResponse?["error"] as? [String: Any],
                   let errorMessage = errorInfo["message"] as? String {
                    print("❌ API返回错误: \(errorMessage)")
                    completion(.failure(.apiError(errorMessage)))
                    return
                }
                
                let results = self.parseAPIResponse(apiResponse, expectedWords: expectedWords)
                print("🎉 识别结果解析完成，共 \(results.count) 个单词")
                completion(.success(results))
            } catch {
                print("❌ 响应解析失败: \(error)")
                completion(.failure(.processingError("Failed to parse response: \(error.localizedDescription)")))
            }
        }.resume()
    }
    
    private func parseAPIResponse(
        _ response: [String: Any]?,
        expectedWords: [String]
    ) -> [HandwritingRecognitionResult] {
        print("🔍 开始解析API响应...")
        
        guard let response = response else {
            print("❌ 响应为空")
            return []
        }
        
        guard let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ 响应格式不正确")
            print("📄 原始响应: \(response)")
            return []
        }
        
        print("📝 GPT-4返回内容:")
        print(content)
        
        // 尝试解析JSON内容
        var jsonContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果内容被包装在代码块中，提取JSON部分
        if jsonContent.hasPrefix("```json") {
            jsonContent = jsonContent.replacingOccurrences(of: "```json", with: "")
            jsonContent = jsonContent.replacingOccurrences(of: "```", with: "")
            jsonContent = jsonContent.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonContent.hasPrefix("```") {
            jsonContent = jsonContent.replacingOccurrences(of: "```", with: "")
            jsonContent = jsonContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let contentData = jsonContent.data(using: .utf8) else {
            print("❌ 内容转换为Data失败")
            return []
        }
        
        do {
            let parsedContent = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
            
            guard let writtenWords = parsedContent?["writtenWords"] as? [[String: Any]] else {
                print("❌ 未找到writtenWords字段")
                print("📄 解析后的内容: \(parsedContent ?? [:])")
                return []
            }
            
            print("✅ 成功解析到 \(writtenWords.count) 个书写单词")
            print("📝 用户书写顺序:")
            
            // 按书写顺序打印用户的实际内容
            let sortedWords = writtenWords.sorted { 
                let pos1 = $0["position"] as? Int ?? 0
                let pos2 = $1["position"] as? Int ?? 0
                return pos1 < pos2
            }
            
            for (index, wordDict) in sortedWords.enumerated() {
                let position = wordDict["position"] as? Int ?? (index + 1)
                let recognizedWord = wordDict["recognizedWord"] as? String ?? ""
                let confidence = wordDict["confidence"] as? Double ?? 0.0
                
                print("   \(position). \(recognizedWord) (置信度: \(String(format: "%.2f", confidence)))")
            }
            
            // 转换为HandwritingRecognitionResult格式，与期望单词进行匹配
            return sortedWords.enumerated().compactMap { (index, wordDict) in
                let recognizedWord = wordDict["recognizedWord"] as? String ?? ""
                let confidence = wordDict["confidence"] as? Double ?? 0.0
                let position = wordDict["position"] as? Int ?? (index + 1)
                
                // 解析位置信息
                var boundingBox = CGRect(
                    x: Double.random(in: 0.1...0.3),
                    y: Double(index) * 0.15 + 0.1,
                    width: Double.random(in: 0.4...0.6),
                    height: 0.1
                )
                
                if let locationDict = wordDict["location"] as? [String: Double],
                   let x = locationDict["x"],
                   let y = locationDict["y"],
                   let width = locationDict["width"],
                   let height = locationDict["height"] {
                    boundingBox = CGRect(x: x, y: y, width: width, height: height)
                }
                
                // 找到对应的期望单词（如果有的话）
                let expectedWord = expectedWords[safe: index] ?? ""
                
                // 简单的正确性判断：只看单词内容是否匹配
                let isCorrect = !expectedWord.isEmpty && 
                               recognizedWord.lowercased() == expectedWord.lowercased()
                
                print("🔄 匹配结果 \(index + 1):")
                print("   - 书写位置: \(position)")
                print("   - 识别单词: '\(recognizedWord)'")
                print("   - 期望单词: '\(expectedWord)'")
                print("   - 内容正确: \(isCorrect ? "✅" : "❌")")
                print("   - 置信度: \(String(format: "%.2f", confidence))")
                
                return HandwritingRecognitionResult(
                    index: index,
                    expectedWord: expectedWord,
                    recognizedWord: recognizedWord,
                    isCorrect: isCorrect,
                    confidence: confidence,
                    boundingBox: boundingBox,
                    actualPosition: position - 1, // 转换为0开始的索引
                    isOrderCorrect: true // 不再判断顺序正确性
                )
            }
        } catch {
            print("❌ JSON解析失败: \(error)")
            print("📄 尝试解析的内容: \(jsonContent)")
            return []
        }
    }
}

