import Foundation
import CoreXLSX

// MARK: - 错误类型
enum MigrationError: Error {
    case excelFileNotFound
    case cannotOpenExcel
}

// MARK: - 数组扩展
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 启动时自动迁移
@MainActor
class StartupMigration {
    static let shared = StartupMigration()
    private let appwriteService = AppwriteService()
    private let appwriteDatabaseManager: AppwriteDatabaseManager
    
    private init() {
        self.appwriteDatabaseManager = AppwriteDatabaseManager(appwriteService: appwriteService)
    }
    
    // MARK: - 静默执行迁移
    func runSilentMigration() async {
        print("🚀 开始静默数据迁移...")
        
        do {
            // 检查数据库是否已有数据
            let hasData = try await appwriteDatabaseManager.hasData()
            if hasData {
                print("ℹ️ 数据库已有数据，跳过迁移")
                return
            }
            
            print("📊 数据库为空，开始迁移...")
            
            // 步骤1: 创建数据库和集合
            print("🗄️ 创建数据库和集合...")
            try await appwriteDatabaseManager.createDatabaseAndCollection()
            
            // 步骤2: 读取Excel数据
            print("📖 读取Excel数据...")
            let excelWords = try await loadWordsFromExcelFile()
            
            guard !excelWords.isEmpty else {
                print("⚠️ Excel文件为空，跳过迁移")
                return
            }
            
            // 步骤3: 上传数据
            print("📤 上传数据到数据库...")
            try await appwriteDatabaseManager.uploadWords(excelWords)
            
            // 步骤4: 验证数据
            print("✅ 验证数据...")
            let uploadedWords = try await appwriteDatabaseManager.loadWords(limit: 100)
            
            print("🎉 静默迁移完成!")
            print("   - 总单词数: \(excelWords.count)")
            print("   - 验证结果: 数据库中有 \(uploadedWords.count) 个单词")
            
        } catch {
            print("❌ 静默迁移失败: \(error)")
        }
    }
    
    // MARK: - 从Excel文件加载数据
    private func loadWordsFromExcelFile() async throws -> [ImportedWord] {
        guard let filePath = Bundle.main.path(forResource: "high_school_words_processed_final", ofType: "xlsx") else {
            throw MigrationError.excelFileNotFound
        }
        
        guard let file = XLSXFile(filepath: filePath) else {
            throw MigrationError.cannotOpenExcel
        }
        
        var importedWords: [ImportedWord] = []
        
        for wbk in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                let worksheet = try file.parseWorksheet(at: path)
                let sharedStrings = try file.parseSharedStrings()
                
                guard let rows = worksheet.data?.rows else {
                    continue
                }
                
                // 跳过标题行，从第二行开始解析
                for (rowIndex, row) in rows.enumerated() {
                    if rowIndex == 0 {
                        continue
                    }
                    
                    let cells = row.cells
                    if cells.count >= 4 {
                        let importedWord = parseRowToImportedWord(
                            cells: cells,
                            sharedStrings: sharedStrings,
                            rowIndex: rowIndex
                        )
                        importedWords.append(importedWord)
                    }
                }
            }
        }
        
        return importedWords
    }
    
    // MARK: - 获取单元格值
    private func getCellValue(_ cell: CoreXLSX.Cell?, sharedStrings: SharedStrings?) -> String {
        guard let cell = cell else { return "" }
        
        if cell.type == .inlineStr {
            if let inlineString = cell.inlineString {
                return inlineString.text ?? ""
            }
            return ""
        }
        
        if let sharedStrings = sharedStrings, let stringValue = cell.stringValue(sharedStrings) {
            return stringValue
        }
        
        if let value = cell.value {
            if let stringIndex = Int(value), let sharedStrings = sharedStrings {
                return sharedStrings.items[stringIndex].text ?? value
            } else {
                return value
            }
        }
        
        return ""
    }
    
    // MARK: - 解析行数据为ImportedWord
    private func parseRowToImportedWord(
        cells: [CoreXLSX.Cell],
        sharedStrings: SharedStrings?,
        rowIndex: Int
    ) -> ImportedWord {
        let english = getCellValue(cells[safe: 3], sharedStrings: sharedStrings)
        let chinese = getCellValue(cells[safe: 4], sharedStrings: sharedStrings)
        let example = getCellValue(cells[safe: 10], sharedStrings: sharedStrings)
        let imageURL = getCellValue(cells[safe: 11], sharedStrings: sharedStrings)
        let etymology = getCellValue(cells[safe: 9], sharedStrings: sharedStrings)
        let memoryTip = getCellValue(cells[safe: 8], sharedStrings: sharedStrings)
        let misleadingEnglishString = getCellValue(cells[safe: 6], sharedStrings: sharedStrings)
        let misleadingChineseString = getCellValue(cells[safe: 7], sharedStrings: sharedStrings)
        
        let misleadingEnglishOptions = misleadingEnglishString.isEmpty ? [] : 
            misleadingEnglishString.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        let misleadingChineseOptions = misleadingChineseString.isEmpty ? [] : 
            misleadingChineseString.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        
        let textbook = getCellValue(cells[safe: 1], sharedStrings: sharedStrings)
        
        return ImportedWord(
            english: english,
            chinese: chinese,
            example: example.isEmpty ? nil : example,
            grade: mapTextbookToGrade(textbook),
            difficulty: "medium",
            category: .daily,
            textbookVersion: mapTextbookVersion(getCellValue(cells[safe: 0], sharedStrings: sharedStrings)),
            courseType: mapCourseType(textbook),
            course: textbook,
            imageURL: imageURL.isEmpty ? nil : imageURL,
            etymology: etymology.isEmpty ? nil : etymology,
            memoryTip: memoryTip.isEmpty ? nil : memoryTip,
            relatedWords: nil,
            misleadingEnglishOptions: misleadingEnglishOptions,
            misleadingChineseOptions: misleadingChineseOptions
        )
    }
    
    // MARK: - 辅助映射函数
    private func mapTextbookToGrade(_ textbook: String) -> Grade {
        if textbook.contains("必修1") || textbook.contains("必修一") {
            return .high1
        } else if textbook.contains("必修2") || textbook.contains("必修二") {
            return .high2
        } else if textbook.contains("必修3") || textbook.contains("必修三") {
            return .high3
        } else if textbook.contains("选修") {
            return .high3
        } else {
            return .high1
        }
    }
    
    private func mapTextbookVersion(_ textbook: String) -> TextbookVersion {
        if textbook.contains("人教版") || textbook.contains("新人教版") {
            return .renjiao
        } else if textbook.contains("外研版") || textbook.contains("外研社") {
            return .waiyan
        } else if textbook.contains("北师大版") {
            return .beishida
        } else {
            return .renjiao
        }
    }
    
    private func mapCourseType(_ textbook: String) -> CourseType {
        if textbook.contains("必修") {
            return .required
        } else if textbook.contains("选修") {
            return .elective
        } else {
            return .required
        }
    }
}

