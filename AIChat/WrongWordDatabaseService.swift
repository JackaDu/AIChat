import Foundation
import SwiftUI

// MARK: - 错题记录数据库服务
class WrongWordDatabaseService: ObservableObject {
    private let appwriteService: AppwriteService
    private let config = AppwriteConfig.shared
    
    init(appwriteService: AppwriteService) {
        self.appwriteService = appwriteService
    }
    
    // MARK: - 创建错题记录
    func createWrongWord(_ wrongWord: WrongWord) async throws -> String {
        print("🔍 WrongWordDatabaseService.createWrongWord 开始: \(wrongWord.word)")
        
        guard let userId = await appwriteService.currentUser?.id else {
            print("❌ 用户未认证，无法创建错题记录")
            throw AppwriteError.userNotAuthenticated
        }
        
        print("🔍 用户ID: \(userId)")
        print("🔍 会话ID: \(await appwriteService.currentSessionId ?? "nil")")
        
        let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.wrongWordsCollectionId)/documents")!
        print("🔍 请求URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(await appwriteService.currentSessionId ?? "")", forHTTPHeaderField: "Authorization")
        
        // 构建数据字典，分步进行以避免编译器超时
        var dataDict: [String: Any] = [:]
        dataDict["userId"] = userId
        dataDict["word"] = wrongWord.word
        dataDict["meaning"] = wrongWord.meaning
        dataDict["context"] = wrongWord.context
        dataDict["learningDirection"] = wrongWord.learningDirection.rawValue
        // 移除 dateAdded，使用 Appwrite 默认的 $createdAt
        dataDict["reviewDates"] = wrongWord.reviewDates.map { ISO8601DateFormatter().string(from: $0) }
        dataDict["nextReviewDate"] = ISO8601DateFormatter().string(from: wrongWord.nextReviewDate)
        dataDict["reviewCount"] = wrongWord.reviewCount
        dataDict["isMastered"] = wrongWord.isMastered
        dataDict["errorCount"] = wrongWord.errorCount
        dataDict["totalAttempts"] = wrongWord.totalAttempts
        dataDict["textbookSource"] = wrongWord.textbookSource?.displayText ?? ""
        dataDict["partOfSpeech"] = wrongWord.partOfSpeech?.rawValue ?? ""
        dataDict["examSource"] = wrongWord.examSource?.rawValue ?? ""
        dataDict["difficulty"] = wrongWord.difficulty.rawValue
        dataDict["lastReviewDate"] = wrongWord.lastReviewDate?.ISO8601Format() ?? ""
        dataDict["consecutiveCorrect"] = wrongWord.consecutiveCorrect
        dataDict["consecutiveWrong"] = wrongWord.consecutiveWrong
        dataDict["deviceId"] = await UIDevice.current.identifierForVendor?.uuidString ?? ""
        dataDict["syncStatus"] = "synced"
        
        let body: [String: Any] = [
            "documentId": wrongWord.id.uuidString,
            "data": dataDict
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📝 创建错题记录到数据库: \(wrongWord.word)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode == 201 {
            let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let documentId = responseData?["$id"] as? String ?? wrongWord.id.uuidString
            print("✅ 错题记录创建成功: \(documentId)")
            return documentId
        } else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["message"] as? String ?? "Unknown error"
            print("❌ 创建错题记录失败: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            throw AppwriteError.apiError("Failed to create wrong word: \(errorMessage)")
        }
    }
    
    // MARK: - 更新错题记录
    func updateWrongWord(_ wrongWord: WrongWord) async throws {
        guard let userId = await appwriteService.currentUser?.id else {
            throw AppwriteError.userNotAuthenticated
        }
        
        let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.wrongWordsCollectionId)/documents/\(wrongWord.id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(await appwriteService.currentSessionId ?? "")", forHTTPHeaderField: "Authorization")
        
        // 构建更新数据字典，分步进行以避免编译器超时
        var updateDataDict: [String: Any] = [:]
        updateDataDict["userId"] = userId
        updateDataDict["word"] = wrongWord.word
        updateDataDict["meaning"] = wrongWord.meaning
        updateDataDict["context"] = wrongWord.context
        updateDataDict["learningDirection"] = wrongWord.learningDirection.rawValue
        // 移除 dateAdded，使用 Appwrite 默认的 $createdAt
        updateDataDict["reviewDates"] = wrongWord.reviewDates.map { ISO8601DateFormatter().string(from: $0) }
        updateDataDict["nextReviewDate"] = ISO8601DateFormatter().string(from: wrongWord.nextReviewDate)
        updateDataDict["reviewCount"] = wrongWord.reviewCount
        updateDataDict["isMastered"] = wrongWord.isMastered
        updateDataDict["errorCount"] = wrongWord.errorCount
        updateDataDict["totalAttempts"] = wrongWord.totalAttempts
        updateDataDict["textbookSource"] = wrongWord.textbookSource?.displayText ?? ""
        updateDataDict["partOfSpeech"] = wrongWord.partOfSpeech?.rawValue ?? ""
        updateDataDict["examSource"] = wrongWord.examSource?.rawValue ?? ""
        updateDataDict["difficulty"] = wrongWord.difficulty.rawValue
        updateDataDict["lastReviewDate"] = wrongWord.lastReviewDate?.ISO8601Format() ?? ""
        updateDataDict["consecutiveCorrect"] = wrongWord.consecutiveCorrect
        updateDataDict["consecutiveWrong"] = wrongWord.consecutiveWrong
        updateDataDict["deviceId"] = await UIDevice.current.identifierForVendor?.uuidString ?? ""
        updateDataDict["syncStatus"] = "synced"
        
        let body: [String: Any] = [
            "data": updateDataDict
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📝 更新错题记录到数据库: \(wrongWord.word)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ 错题记录更新成功")
        } else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["message"] as? String ?? "Unknown error"
            print("❌ 更新错题记录失败: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            throw AppwriteError.apiError("Failed to update wrong word: \(errorMessage)")
        }
    }
    
    // MARK: - 删除错题记录
    func deleteWrongWord(_ wrongWord: WrongWord) async throws {
        guard await appwriteService.currentUser?.id != nil else {
            throw AppwriteError.userNotAuthenticated
        }
        
        let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.wrongWordsCollectionId)/documents/\(wrongWord.id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(await appwriteService.currentSessionId ?? "")", forHTTPHeaderField: "Authorization")
        
        print("📝 删除错题记录从数据库: \(wrongWord.word)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode == 204 {
            print("✅ 错题记录删除成功")
        } else {
            print("❌ 删除错题记录失败: HTTP \(httpResponse.statusCode)")
            throw AppwriteError.apiError("Failed to delete wrong word")
        }
    }
    
    // MARK: - 获取用户的所有错题记录
    func fetchUserWrongWords() async throws -> [WrongWord] {
        guard let userId = await appwriteService.currentUser?.id else {
            throw AppwriteError.userNotAuthenticated
        }
        
        let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.wrongWordsCollectionId)/documents?queries[]=equal(\"userId\",\"\(userId)\")")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(await appwriteService.currentSessionId ?? "")", forHTTPHeaderField: "Authorization")
        
        print("📝 获取用户错题记录: \(userId)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let documents = responseData?["documents"] as? [[String: Any]] ?? []
            
            let wrongWords = documents.compactMap { doc -> WrongWord? in
                return parseWrongWordFromDocument(doc)
            }
            
            print("✅ 获取到 \(wrongWords.count) 个错题记录")
            return wrongWords
        } else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["message"] as? String ?? "Unknown error"
            print("❌ 获取错题记录失败: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            throw AppwriteError.apiError("Failed to fetch wrong words: \(errorMessage)")
        }
    }
    
    // MARK: - 同步错题记录
    func syncWrongWords(_ wrongWords: [WrongWord]) async throws {
        print("🔄 开始同步错题记录到数据库...")
        
        for wrongWord in wrongWords {
            do {
                // 尝试更新，如果失败则创建
                try await updateWrongWord(wrongWord)
            } catch {
                // 如果更新失败，尝试创建
                do {
                    _ = try await createWrongWord(wrongWord)
                } catch {
                    print("❌ 同步错题记录失败: \(wrongWord.word) - \(error.localizedDescription)")
                }
            }
        }
        
        print("✅ 错题记录同步完成")
    }
    
    // MARK: - 解析数据库文档为 WrongWord 对象
    private func parseWrongWordFromDocument(_ doc: [String: Any]) -> WrongWord? {
        guard let data = doc["data"] as? [String: Any],
              let word = data["word"] as? String,
              let meaning = data["meaning"] as? String,
              let learningDirectionString = data["learningDirection"] as? String,
              let learningDirection = LearningDirection(rawValue: learningDirectionString),
              // 移除 dateAdded 解析，使用 Appwrite 的 $createdAt
              let nextReviewDateString = data["nextReviewDate"] as? String,
              let nextReviewDate = ISO8601DateFormatter().date(from: nextReviewDateString),
              let reviewCount = data["reviewCount"] as? Int,
              let isMastered = data["isMastered"] as? Bool,
              let errorCount = data["errorCount"] as? Int,
              let totalAttempts = data["totalAttempts"] as? Int,
              let difficultyString = data["difficulty"] as? String,
              let difficulty = WordDifficulty(rawValue: difficultyString),
              let consecutiveCorrect = data["consecutiveCorrect"] as? Int,
              let consecutiveWrong = data["consecutiveWrong"] as? Int else {
            return nil
        }
        
        let context = data["context"] as? String ?? ""
        let reviewDatesStrings = data["reviewDates"] as? [String] ?? []
        let reviewDates = reviewDatesStrings.compactMap { ISO8601DateFormatter().date(from: $0) }
        
        let _ = data["textbookSource"] as? String ?? ""
        let textbookSource: TextbookSource? = nil // 暂时设为 nil，后续可以解析
        
        let partOfSpeechString = data["partOfSpeech"] as? String ?? ""
        let partOfSpeech = partOfSpeechString.isEmpty ? nil : PartOfSpeech(rawValue: partOfSpeechString)
        
        let examSourceString = data["examSource"] as? String ?? ""
        let examSource = examSourceString.isEmpty ? nil : ExamSource(rawValue: examSourceString)
        
        let lastReviewDateString = data["lastReviewDate"] as? String ?? ""
        let lastReviewDate = lastReviewDateString.isEmpty ? nil : ISO8601DateFormatter().date(from: lastReviewDateString)
        
        var wrongWord = WrongWord(
            word: word,
            meaning: meaning,
            context: context,
            learningDirection: learningDirection,
            textbookSource: textbookSource,
            partOfSpeech: partOfSpeech,
            examSource: examSource,
            difficulty: difficulty
        )
        
        // 设置从数据库读取的值 (移除 dateAdded，使用 Appwrite 的 $createdAt)
        wrongWord.reviewDates = reviewDates
        wrongWord.nextReviewDate = nextReviewDate
        wrongWord.reviewCount = reviewCount
        wrongWord.isMastered = isMastered
        wrongWord.errorCount = errorCount
        wrongWord.totalAttempts = totalAttempts
        wrongWord.lastReviewDate = lastReviewDate
        wrongWord.consecutiveCorrect = consecutiveCorrect
        wrongWord.consecutiveWrong = consecutiveWrong
        
        return wrongWord
    }
}

// MARK: - 扩展 AppwriteError
extension AppwriteError {
    static let userNotAuthenticated = AppwriteError.apiError("User not authenticated")
}
