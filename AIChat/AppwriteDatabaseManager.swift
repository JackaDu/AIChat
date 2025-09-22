import Foundation

// MARK: - Appwrite数据库管理器
class AppwriteDatabaseManager: ObservableObject {
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingStatus = ""
    
    private let appwriteService: AppwriteService
    private let databaseId = "english_learning"
    private let collectionId = "words_collection"
    
    init(appwriteService: AppwriteService) {
        self.appwriteService = appwriteService
    }
    
    // MARK: - 创建数据库和集合
    func createDatabaseAndCollection() async throws {
        print("🗄️ 开始创建Appwrite数据库和集合...")
        
        await MainActor.run {
            isLoading = true
            loadingStatus = "创建数据库..."
        }
        
        do {
            // 1. 创建数据库
            try await createDatabase()
            await MainActor.run { loadingStatus = "创建集合..." }
            
            // 2. 创建集合
            try await createCollection()
            await MainActor.run { loadingStatus = "创建属性..." }
            
            // 3. 创建属性
            try await createAttributes()
            await MainActor.run { loadingStatus = "创建索引..." }
            
            // 4. 创建索引
            try await createIndexes()
            
            await MainActor.run {
                isLoading = false
                loadingStatus = "数据库创建完成!"
            }
            
            print("✅ Appwrite数据库和集合创建成功!")
            
        } catch {
            await MainActor.run {
                isLoading = false
                loadingStatus = "创建失败: \(error.localizedDescription)"
            }
            print("❌ 创建数据库失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 创建数据库
    private func createDatabase() async throws {
        do {
            let response = try await appwriteService.createDatabase(
                databaseId: databaseId,
                name: "Words Database"
            )
            print("✅ 数据库创建成功: \(response)")
        } catch {
            // 如果数据库已存在，忽略错误
            if error.localizedDescription.contains("already exists") {
                print("ℹ️ 数据库已存在，跳过创建")
            } else {
                throw error
            }
        }
    }
    
    // MARK: - 创建集合
    private func createCollection() async throws {
        do {
            let response = try await appwriteService.createCollection(
                databaseId: databaseId,
                collectionId: collectionId,
                name: "Words Collection",
                permissions: ["read(\"any\")", "write(\"any\")"]
            )
            print("✅ 集合创建成功: \(response)")
        } catch {
            // 如果集合已存在，忽略错误
            if error.localizedDescription.contains("already exists") {
                print("ℹ️ 集合已存在，跳过创建")
            } else {
                throw error
            }
        }
    }
    
    // MARK: - 创建属性
    private func createAttributes() async throws {
        let attributes = [
            ("english", "string", true),
            ("chinese", "string", true),
            ("example", "string", false),
            ("imageURL", "string", false),
            ("etymology", "string", false),
            ("memoryTip", "string", false),
            ("misleadingEnglishOptions", "string", false),
            ("misleadingChineseOptions", "string", false),
            ("grade", "string", false),
            ("difficulty", "string", false),
            ("category", "string", false),
            ("textbookVersion", "string", false),
            ("courseType", "string", false),
            ("course", "string", false)
        ]
        
        for (key, type, required) in attributes {
            do {
                try await appwriteService.createStringAttribute(
                    databaseId: databaseId,
                    collectionId: collectionId,
                    key: key,
                    size: 1000,
                    required: required
                )
                print("✅ 创建属性成功: \(key)")
            } catch {
                // 如果属性已存在，忽略错误
                if error.localizedDescription.contains("already exists") {
                    print("ℹ️ 属性 \(key) 已存在，跳过创建")
                } else {
                    print("⚠️ 创建属性失败 \(key): \(error)")
                    // 继续创建其他属性，不中断流程
                }
            }
        }
    }
    
    // MARK: - 创建索引
    private func createIndexes() async throws {
        let indexes = [
            ("english_index", "english", "key"),
            ("chinese_index", "chinese", "key"),
            ("grade_index", "grade", "key"),
            ("difficulty_index", "difficulty", "key")
        ]
        
        for (indexId, key, type) in indexes {
            do {
                try await appwriteService.createIndex(
                    databaseId: databaseId,
                    collectionId: collectionId,
                    key: indexId,
                    type: type,
                    attributes: [key]
                )
                print("✅ 创建索引成功: \(indexId)")
            } catch {
                // 如果索引已存在，忽略错误
                if error.localizedDescription.contains("already exists") {
                    print("ℹ️ 索引 \(indexId) 已存在，跳过创建")
                } else {
                    print("⚠️ 创建索引失败 \(indexId): \(error)")
                    // 继续创建其他索引，不中断流程
                }
            }
        }
    }
    
    // MARK: - 批量上传单词数据
    func uploadWords(_ words: [ImportedWord]) async throws {
        print("📤 开始上传 \(words.count) 个单词到Appwrite数据库...")
        
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
            loadingStatus = "准备上传数据..."
        }
        
        let batchSize = 25 // Appwrite批量操作限制
        let totalBatches = (words.count + batchSize - 1) / batchSize
        var successfulUploads = 0
        
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, words.count)
            let batch = Array(words[startIndex..<endIndex])
            
            await MainActor.run {
                loadingStatus = "上传批次 \(batchIndex + 1)/\(totalBatches)..."
                loadingProgress = Double(batchIndex) / Double(totalBatches)
            }
            
            try await uploadBatch(batch)
            successfulUploads += batch.count
            
            print("✅ 完成批次 \(batchIndex + 1)/\(totalBatches)")
        }
        
        await MainActor.run {
            isLoading = false
            loadingProgress = 1.0
            loadingStatus = "上传完成! 成功上传 \(successfulUploads) 个单词"
        }
        
        print("✅ 所有单词上传完成，共 \(successfulUploads) 个")
    }
    
    // MARK: - 上传单个批次
    private func uploadBatch(_ batch: [ImportedWord]) async throws {
        for word in batch {
            let documentData: [String: Any] = [
                "english": word.english,
                "chinese": word.chinese,
                "example": word.example ?? "",
                "imageURL": word.imageURL ?? "",
                "etymology": word.etymology ?? "",
                "memoryTip": word.memoryTip ?? "",
                "misleadingEnglishOptions": try JSONSerialization.data(withJSONObject: word.misleadingEnglishOptions).base64EncodedString(),
                "misleadingChineseOptions": try JSONSerialization.data(withJSONObject: word.misleadingChineseOptions).base64EncodedString(),
                "grade": word.grade.rawValue,
                "difficulty": word.difficulty,
                "category": word.category.rawValue,
                "textbookVersion": word.textbookVersion.rawValue,
                "courseType": word.courseType.rawValue,
                "course": word.course
            ]
            
            do {
                try await appwriteService.createDocument(
                    databaseId: databaseId,
                    collectionId: collectionId,
                    documentId: "unique()",
                    data: documentData
                )
            } catch {
                print("⚠️ 上传单词失败 \(word.english): \(error)")
                // 继续上传其他单词，不中断流程
            }
        }
    }
    
    // MARK: - 从数据库加载单词
    func loadWords(limit: Int = 100, offset: Int = 0) async throws -> [ImportedWord] {
        print("📥 从Appwrite数据库加载单词...")
        
        await MainActor.run {
            isLoading = true
            loadingStatus = "从数据库加载单词..."
        }
        
        do {
            let documents = try await appwriteService.listDocuments(
                databaseId: databaseId,
                collectionId: collectionId,
                limit: limit,
                offset: offset
            )
            
            let words = documents.compactMap { document -> ImportedWord? in
                return convertDocumentToImportedWord(document)
            }
            
            await MainActor.run {
                isLoading = false
                loadingStatus = "加载完成"
            }
            
            print("✅ 从数据库加载了 \(words.count) 个单词")
            return words
            
        } catch {
            await MainActor.run {
                isLoading = false
                loadingStatus = "加载失败"
            }
            print("❌ 从数据库加载失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 从数据库加载StudyWord
    func loadStudyWords(grade: Grade, textbook: String, unit: String, limit: Int = 100, offset: Int = 0) async throws -> [StudyWord] {
        print("📥 从Appwrite数据库加载StudyWord...")
        print("- 年级: \(grade)")
        print("- 教材: \(textbook)")
        print("- 单元: \(unit)")
        
        await MainActor.run {
            isLoading = true
            loadingStatus = "从数据库加载单词..."
        }
        
        do {
            let documents = try await appwriteService.listDocuments(
                databaseId: databaseId,
                collectionId: collectionId,
                limit: limit,
                offset: offset
            )
            
            let studyWords = documents.compactMap { document -> StudyWord? in
                return convertDocumentToStudyWord(document)
            }
            
            await MainActor.run {
                isLoading = false
                loadingStatus = "加载完成"
            }
            
            print("✅ 从数据库加载了 \(studyWords.count) 个StudyWord")
            return studyWords
            
        } catch {
            await MainActor.run {
                isLoading = false
                loadingStatus = "加载失败: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - 转换文档为ImportedWord
    private func convertDocumentToImportedWord(_ document: [String: Any]) -> ImportedWord? {
        guard let english = document["english"] as? String,
              let chinese = document["chinese"] as? String else {
            return nil
        }
        
        let example = document["example"] as? String
        let imageURL = document["imageURL"] as? String
        let etymology = document["etymology"] as? String
        let memoryTip = document["memoryTip"] as? String
        let grade = Grade(rawValue: document["grade"] as? String ?? "high1") ?? .high1
        let difficulty = document["difficulty"] as? String ?? "medium"
        let category = VocabularyType(rawValue: document["category"] as? String ?? "daily") ?? .daily
        let textbookVersion = TextbookVersion(rawValue: document["textbookVersion"] as? String ?? "renjiao") ?? .renjiao
        let courseType = CourseType(rawValue: document["courseType"] as? String ?? "required") ?? .required
        let course = document["course"] as? String ?? ""
        
        // 解析误导选项
        var misleadingEnglishOptions: [String] = []
        var misleadingChineseOptions: [String] = []
        
        // 调试：检查原始数据格式和所有可能的字段名
        if english.lowercased() == "lecture" {
            print("🔍 调试lecture单词的原始数据库字段:")
            print("   - 所有字段: \(document.keys.sorted())")
            
            // 检查所有可能的误导选项字段名
            let possibleEnglishFields = ["misleadingEnglishOptions", "misleadingEn", "misleadingEnglish", "misleading_english"]
            let possibleChineseFields = ["misleadingChineseOptions", "misleadingCh", "misleadingChinese", "misleading_chinese"]
            
            for field in possibleEnglishFields {
                if let value = document[field] {
                    print("   - \(field): \(value) (类型: \(type(of: value)))")
                }
            }
            
            for field in possibleChineseFields {
                if let value = document[field] {
                    print("   - \(field): \(value) (类型: \(type(of: value)))")
                }
            }
        }
        
        // 解析英文误导选项
        if let englishArray = document["misleadingEnglishOptions"] as? [String] {
            // 方式1: 直接的字符串数组
            misleadingEnglishOptions = englishArray
        } else if let englishOptionsString = document["misleadingEnglishOptions"] as? String {
            // 方式2: JSON字符串
            if let englishData = englishOptionsString.data(using: .utf8),
               let englishArray = try? JSONSerialization.jsonObject(with: englishData) as? [String] {
                misleadingEnglishOptions = englishArray
            }
            // 方式3: Base64编码的JSON字符串
            else if let englishData = Data(base64Encoded: englishOptionsString),
                    let englishArray = try? JSONSerialization.jsonObject(with: englishData) as? [String] {
                misleadingEnglishOptions = englishArray
            }
        }
        
        // 解析中文误导选项
        if let chineseArray = document["misleadingChineseOptions"] as? [String] {
            // 方式1: 直接的字符串数组
            misleadingChineseOptions = chineseArray
        } else if let chineseOptionsString = document["misleadingChineseOptions"] as? String {
            // 方式2: JSON字符串
            if let chineseData = chineseOptionsString.data(using: .utf8),
               let chineseArray = try? JSONSerialization.jsonObject(with: chineseData) as? [String] {
                misleadingChineseOptions = chineseArray
            }
            // 方式3: Base64编码的JSON字符串
            else if let chineseData = Data(base64Encoded: chineseOptionsString),
                    let chineseArray = try? JSONSerialization.jsonObject(with: chineseData) as? [String] {
                misleadingChineseOptions = chineseArray
            }
        }
        
        // 调试结果
        if english.lowercased() == "lecture" {
            print("🔍 解析后的结果:")
            print("   - misleadingEnglishOptions: \(misleadingEnglishOptions)")
            print("   - misleadingChineseOptions: \(misleadingChineseOptions)")
        }
        
        return ImportedWord(
            english: english,
            chinese: chinese,
            example: example?.isEmpty == false ? example : nil,
            grade: grade,
            difficulty: difficulty,
            category: category,
            textbookVersion: textbookVersion,
            courseType: courseType,
            course: course,
            imageURL: imageURL?.isEmpty == false ? imageURL : nil,
            etymology: etymology?.isEmpty == false ? etymology : nil,
            memoryTip: memoryTip?.isEmpty == false ? memoryTip : nil,
            relatedWords: nil,
            misleadingEnglishOptions: misleadingEnglishOptions,
            misleadingChineseOptions: misleadingChineseOptions
        )
    }
    
    // MARK: - 转换文档为StudyWord
    private func convertDocumentToStudyWord(_ document: [String: Any]) -> StudyWord? {
        guard let english = document["english"] as? String,
              let chinese = document["chinese"] as? String else {
            return nil
        }
        
        let example = document["example"] as? String
        let imageURL = document["imageURL"] as? String
        let etymology = document["etymology"] as? String
        let memoryTip = document["memoryTip"] as? String
        let difficulty = document["difficulty"] as? String ?? "中等"
        let category = document["category"] as? String ?? "词汇"
        
        // 解析年级
        let gradeString = document["grade"] as? String ?? "high1"
        let grade = Grade(rawValue: gradeString) ?? .high1
        
        // 解析预生成选项
        var misleadingEnglishOptions: [String] = []
        var misleadingChineseOptions: [String] = []
        
        // 调试：检查 impression 单词的原始数据
        if english.lowercased() == "impression" {
            print("🔍 调试 impression 单词的原始数据库字段:")
            print("   - 所有字段: \(document.keys.sorted())")
            print("   - misleadingEnglishOptions 原始值: \(document["misleadingEnglishOptions"] ?? "nil")")
            print("   - misleadingChineseOptions 原始值: \(document["misleadingChineseOptions"] ?? "nil")")
            print("   - misleadingEnglishOptions 类型: \(type(of: document["misleadingEnglishOptions"]))")
            print("   - misleadingChineseOptions 类型: \(type(of: document["misleadingChineseOptions"]))")
        }
        
        // 解析英文误导选项
        if let englishArray = document["misleadingEnglishOptions"] as? [String] {
            misleadingEnglishOptions = englishArray
        } else if let englishOptionsString = document["misleadingEnglishOptions"] as? String {
            if let englishData = englishOptionsString.data(using: .utf8),
               let englishArray = try? JSONSerialization.jsonObject(with: englishData) as? [String] {
                misleadingEnglishOptions = englishArray
            } else if let englishData = Data(base64Encoded: englishOptionsString),
                      let englishArray = try? JSONSerialization.jsonObject(with: englishData) as? [String] {
                misleadingEnglishOptions = englishArray
            }
        }
        
        // 解析中文误导选项
        if let chineseArray = document["misleadingChineseOptions"] as? [String] {
            misleadingChineseOptions = chineseArray
        } else if let chineseOptionsString = document["misleadingChineseOptions"] as? String {
            if let chineseData = chineseOptionsString.data(using: .utf8),
               let chineseArray = try? JSONSerialization.jsonObject(with: chineseData) as? [String] {
                misleadingChineseOptions = chineseArray
            } else if let chineseData = Data(base64Encoded: chineseOptionsString),
                      let chineseArray = try? JSONSerialization.jsonObject(with: chineseData) as? [String] {
                misleadingChineseOptions = chineseArray
            }
        }
        
        // 调试：显示解析结果
        if english.lowercased() == "impression" {
            print("🔍 impression 解析结果:")
            print("   - misleadingEnglishOptions: \(misleadingEnglishOptions)")
            print("   - misleadingChineseOptions: \(misleadingChineseOptions)")
        }
        
        // 创建StudyWord
        var studyWord = StudyWord(
            word: english,
            meaning: chinese,
            example: example?.isEmpty == false ? example ?? "" : "",
            difficulty: difficulty,
            category: category,
            grade: grade,
            source: .imported,
            isCorrect: nil,
            answerTime: nil,
            preGeneratedOptions: nil,
            imageURL: imageURL?.isEmpty == false ? imageURL : nil,
            etymology: etymology?.isEmpty == false ? etymology : nil,
            memoryTip: memoryTip?.isEmpty == false ? memoryTip : nil,
            relatedWords: nil
        )
        
        // 设置预生成选项字段
        studyWord.misleadingChineseOptions = misleadingChineseOptions
        studyWord.misleadingEnglishOptions = misleadingEnglishOptions
        
        return studyWord
    }
    
    // MARK: - 检查数据库是否有数据
    func hasData() async throws -> Bool {
        do {
            let documents = try await appwriteService.listDocuments(
                databaseId: databaseId,
                collectionId: collectionId,
                limit: 1
            )
            return !documents.isEmpty
        } catch {
            print("❌ 检查数据库数据失败: \(error)")
            return false
        }
    }
    
    // MARK: - 清空数据库
    func clearDatabase() async throws {
        print("🗑️ 清空Appwrite数据库...")
        
        do {
            // 获取所有文档
            let documents = try await appwriteService.listDocuments(
                databaseId: databaseId,
                collectionId: collectionId,
                limit: 10000
            )
            
            // 删除所有文档
            for document in documents {
                if let documentId = document["$id"] as? String {
                    try await appwriteService.deleteDocument(
                        databaseId: databaseId,
                        collectionId: collectionId,
                        documentId: documentId
                    )
                }
            }
            
            print("✅ 数据库清空完成")
        } catch {
            print("❌ 清空数据库失败: \(error)")
            throw error
        }
    }
}





