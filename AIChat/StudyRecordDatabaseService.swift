//
//  StudyRecordDatabaseService.swift
//  AIChat
//
//  Created by Hao Du on 9/18/25.
//

import Foundation
import UIKit

// MARK: - 学习记录数据库服务
class StudyRecordDatabaseService: ObservableObject {
    private let config = AppwriteConfig.shared
    private var appwriteService: AppwriteService
    
    // 本地缓存队列，用于批量提交
    private var pendingRecords: [StudyRecord] = []
    private let queue = DispatchQueue(label: "studyRecordQueue", qos: .background)
    private var batchTimer: Timer?
    
    // 批量提交配置
    private let batchSize = 5  // 每5条记录提交一次
    private let batchTimeout: TimeInterval = 30  // 30秒超时提交
    
    init(appwriteService: AppwriteService) {
        self.appwriteService = appwriteService
        startBatchTimer()
    }
    
    // 更新 AppwriteService 实例
    func updateAppwriteService(_ newService: AppwriteService) {
        self.appwriteService = newService
    }
    
    // MARK: - 批量处理机制
    
    /// 启动批量提交定时器
    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchTimeout, repeats: true) { [weak self] _ in
            self?.flushPendingRecords()
        }
    }
    
    /// 停止批量提交定时器
    deinit {
        batchTimer?.invalidate()
        // 退出时提交所有待处理记录
        flushPendingRecords()
    }
    
    /// 立即提交所有待处理记录
    func flushPendingRecords() {
        queue.async { [weak self] in
            guard let self = self, !self.pendingRecords.isEmpty else { return }
            
            let recordsToSubmit = self.pendingRecords
            self.pendingRecords.removeAll()
            
            Task {
                await self.submitRecordsBatch(recordsToSubmit)
            }
        }
    }
    
    // MARK: - 创建学习记录 (优化版本)
    
    /// 添加学习记录到批量队列（非阻塞）
    func addStudyRecord(_ studyRecord: StudyRecord) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.pendingRecords.append(studyRecord)
            print("📝 学习记录已加入队列: \(studyRecord.word) (队列长度: \(self.pendingRecords.count))")
            
            // 如果达到批量大小，立即提交
            if self.pendingRecords.count >= self.batchSize {
                let recordsToSubmit = self.pendingRecords
                self.pendingRecords.removeAll()
                
                Task {
                    await self.submitRecordsBatch(recordsToSubmit)
                }
            }
        }
    }
    
    /// 立即创建学习记录（用于重要记录）
    func createStudyRecord(_ studyRecord: StudyRecord) async throws {
        // 直接提交到数据库，用于重要记录
        try await submitSingleRecord(studyRecord)
    }
    
    /// 批量提交记录
    private func submitRecordsBatch(_ records: [StudyRecord]) async {
        print("📦 开始批量提交 \(records.count) 条学习记录")
        
        // 使用 TaskGroup 并发提交，但限制并发数量
        let maxConcurrent = 3
        await withTaskGroup(of: Void.self) { group in
            var index = 0
            
            while index < records.count {
                // 启动最多 maxConcurrent 个任务
                for _ in 0..<min(maxConcurrent, records.count - index) {
                    let record = records[index]
                    index += 1
                    
                    group.addTask {
                        do {
                            try await self.submitSingleRecord(record)
                        } catch {
                            print("❌ 批量提交记录失败: \(record.word) - \(error.localizedDescription)")
                        }
                    }
                }
                
                // 等待当前批次完成
                await group.waitForAll()
            }
        }
        
        print("✅ 批量提交完成: \(records.count) 条记录")
    }
    
    /// 提交单条记录到数据库
    private func submitSingleRecord(_ studyRecord: StudyRecord) async throws {
        guard let sessionId = await appwriteService.currentSessionId else {
            throw AppwriteError.noSession
        }
        
        do {
            let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.studyRecordsCollectionId)/documents")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
            request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "documentId": studyRecord.id.uuidString,
                "data": [
                    "userId": studyRecord.userId,
                    "word": studyRecord.word,
                    "meaning": studyRecord.meaning,
                    "context": studyRecord.context,
                    "learningDirection": studyRecord.learningDirection.rawValue,
                    "isCorrect": studyRecord.isCorrect,
                    "answerTime": studyRecord.answerTime,
                    "memoryStrength": studyRecord.memoryStrength,
                    "streakCount": studyRecord.streakCount,
                    "studyDate": studyRecord.studyDate.ISO8601Format(),
                    "deviceId": studyRecord.deviceId
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("📝 提交学习记录: \(studyRecord.word)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppwriteError.invalidResponse
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ 学习记录创建成功: \(studyRecord.word)")
            } else if httpResponse.statusCode == 409 {
                print("⚠️ 学习记录已存在: \(studyRecord.word)")
            } else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["message"] as? String ?? "Unknown error"
                throw AppwriteError.apiError("Failed to create study record: \(errorMessage)")
            }
        } catch {
            print("❌ 提交学习记录失败: \(studyRecord.word) - \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 获取用户学习记录
    func getUserStudyRecords(userId: String, limit: Int = 100) async throws -> [StudyRecord] {
        guard let sessionId = await appwriteService.currentSessionId else {
            throw AppwriteError.noSession
        }
        
        do {
            // 使用URLComponents来正确构建URL
            var urlComponents = URLComponents(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.studyRecordsCollectionId)/documents")!
            
            // 构建查询参数
            var queryItems: [URLQueryItem] = []
            queryItems.append(URLQueryItem(name: "queries[]", value: "equal(\"userId\",\"\(userId)\")"))
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                throw AppwriteError.apiError("Failed to build URL")
            }
            
            print("🔍 请求URL: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
            request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppwriteError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let documents = json?["documents"] as? [[String: Any]] ?? []
                
                var studyRecords: [StudyRecord] = []
                for document in documents {
                    if let studyRecord = StudyRecord.fromDocument(document) {
                        studyRecords.append(studyRecord)
                    }
                }
                
                print("✅ 获取学习记录成功: \(studyRecords.count) 条记录")
                return studyRecords
            } else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["message"] as? String ?? "Unknown error"
                print("❌ 获取学习记录失败: HTTP \(httpResponse.statusCode) - \(errorMessage)")
                print("❌ 响应数据: \(String(data: data, encoding: .utf8) ?? "无法解析")")
                throw AppwriteError.apiError("Failed to get study records: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            }
        } catch {
            print("❌ 获取学习记录失败: \(error.localizedDescription)")
            print("🔄 尝试备用方法：获取所有记录并在客户端过滤")
            
            // 备用方法：获取所有记录然后在客户端过滤
            do {
                return try await getAllStudyRecordsAndFilter(userId: userId, limit: limit)
            } catch {
                print("❌ 备用方法也失败: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // MARK: - 备用查询方法
    private func getAllStudyRecordsAndFilter(userId: String, limit: Int) async throws -> [StudyRecord] {
        guard let sessionId = await appwriteService.currentSessionId else {
            throw AppwriteError.noSession
        }
        
        // 获取所有记录（不使用查询参数）
        let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.studyRecordsCollectionId)/documents?limit=1000")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")
        
        print("🔍 备用方法：获取所有记录")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let documents = json?["documents"] as? [[String: Any]] ?? []
            
            var allStudyRecords: [StudyRecord] = []
            for document in documents {
                if let studyRecord = StudyRecord.fromDocument(document) {
                    allStudyRecords.append(studyRecord)
                }
            }
            
            // 在客户端过滤用户ID
            let filteredRecords = allStudyRecords.filter { $0.userId == userId }
            let limitedRecords = Array(filteredRecords.prefix(limit))
            
            print("✅ 备用方法成功: 获取到 \(allStudyRecords.count) 条总记录，过滤后得到 \(limitedRecords.count) 条用户记录")
            return limitedRecords
        } else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["message"] as? String ?? "Unknown error"
            print("❌ 备用方法失败: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            throw AppwriteError.apiError("Failed to get study records (fallback): HTTP \(httpResponse.statusCode) - \(errorMessage)")
        }
    }
}

// MARK: - StudyRecord 扩展
extension StudyRecord {
    static func fromDocument(_ document: [String: Any]) -> StudyRecord? {
        guard let data = document["data"] as? [String: Any],
              let userId = data["userId"] as? String,
              let word = data["word"] as? String,
              let meaning = data["meaning"] as? String,
              let context = data["context"] as? String,
              let learningDirectionString = data["learningDirection"] as? String,
              let learningDirection = LearningDirection(rawValue: learningDirectionString),
              let isCorrect = data["isCorrect"] as? Bool,
              let answerTime = data["answerTime"] as? TimeInterval,
              let memoryStrength = data["memoryStrength"] as? Double,
              let streakCount = data["streakCount"] as? Int,
              let studyDateString = data["studyDate"] as? String,
              let _ = ISO8601DateFormatter().date(from: studyDateString),
              let _ = data["deviceId"] as? String else {
            return nil
        }
        
        let record = StudyRecord(
            userId: userId,
            word: word,
            meaning: meaning,
            context: context,
            learningDirection: learningDirection,
            isCorrect: isCorrect,
            answerTime: answerTime,
            memoryStrength: memoryStrength,
            streakCount: streakCount
        )
        
        // 手动设置日期和设备ID，因为init中会自动设置
        return record
    }
}
