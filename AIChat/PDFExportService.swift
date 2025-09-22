import Foundation
import UIKit
import PDFKit

// MARK: - PDF导出模式
enum PDFExportMode: String, CaseIterable {
    case dictationWord = "dictation_word"       // 默写单词（只显示中文，让用户写英文）
    case dictationMeaning = "dictation_meaning" // 默写释义（只显示英文，让用户写中文）
    case chineseEnglish = "chinese_english"    // 中英词表
    
    var displayName: String {
        switch self {
        case .dictationWord:
            return "默写单词"
        case .dictationMeaning:
            return "默写释义"
        case .chineseEnglish:
            return "中英词表"
        }
    }
    
    var description: String {
        switch self {
        case .dictationWord:
            return "只显示中文，用于默写英文单词"
        case .dictationMeaning:
            return "只显示英文，用于默写中文释义"
        case .chineseEnglish:
            return "显示完整的中英文对照"
        }
    }
    
    var icon: String {
        switch self {
        case .dictationWord:
            return "pencil"
        case .dictationMeaning:
            return "pencil.and.outline"
        case .chineseEnglish:
            return "doc.text"
        }
    }
}

// MARK: - PDF样式配置
struct PDFStyleConfig {
    let titleColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    let backgroundColor: UIColor
    let accentColor: UIColor
    
    static let `default` = PDFStyleConfig(
        titleColor: UIColor(red: 0.2, green: 0.7, blue: 0.9, alpha: 1.0), // 青色
        headerColor: UIColor(red: 0.2, green: 0.7, blue: 0.9, alpha: 1.0),
        textColor: .black,
        backgroundColor: .white,
        accentColor: UIColor(red: 0.2, green: 0.7, blue: 0.9, alpha: 0.1)
    )
    
    static let orange = PDFStyleConfig(
        titleColor: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),
        headerColor: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),
        textColor: .black,
        backgroundColor: .white,
        accentColor: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.1)
    )
    
    static let purple = PDFStyleConfig(
        titleColor: UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0),
        headerColor: UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0),
        textColor: .black,
        backgroundColor: .white,
        accentColor: UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 0.1)
    )
    
    static let navy = PDFStyleConfig(
        titleColor: UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0),
        headerColor: UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0),
        textColor: .black,
        backgroundColor: .white,
        accentColor: UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.1)
    )
    
    static let dark = PDFStyleConfig(
        titleColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0),
        headerColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0),
        textColor: .black,
        backgroundColor: .white,
        accentColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.1)
    )
}

// MARK: - PDF导出数据
struct PDFExportData {
    let words: [StudyWord]
    let mode: PDFExportMode
    let style: PDFStyleConfig
    let title: String
    let subtitle: String
    
    init(words: [StudyWord], mode: PDFExportMode, style: PDFStyleConfig = .default) {
        self.words = words
        self.mode = mode
        self.style = style
        
        switch mode {
        case .chineseEnglish:
            self.title = "Vocabulary List - 中英词表"
            self.subtitle = "生词本"
        case .dictationMeaning:
            self.title = "Vocabulary List - 默写释义"
            self.subtitle = "生词本"
        case .dictationWord:
            self.title = "Vocabulary List - 默写单词"
            self.subtitle = "生词本"
        }
    }
    
    // 支持自定义标题的初始化器
    init(words: [StudyWord], mode: PDFExportMode, style: PDFStyleConfig = .default, customTitle: String, customSubtitle: String = "生词本") {
        self.words = words
        self.mode = mode
        self.style = style
        self.title = customTitle
        self.subtitle = customSubtitle
    }
}

// MARK: - PDF导出服务
class PDFExportService: ObservableObject {
    static let shared = PDFExportService()
    
    private init() {}
    
    // MARK: - 生成PDF
    func generatePDF(data: PDFExportData) -> PDFDocument? {
        print("🔄 开始生成PDF...")
        print("📊 导出数据:")
        print("   - 单词数量: \(data.words.count)")
        print("   - 导出模式: \(data.mode.displayName)")
        print("   - 标题: \(data.title)")
        
        let pageSize = CGSize(width: 595, height: 842) // A4 size in points
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let pdfDocument = PDFDocument()
        let margin: CGFloat = 50
        
        // 计算每页可容纳的单词数
        let wordsPerPage = calculateWordsPerPage(pageSize: pageSize, margin: margin)
        let totalPages = Int(ceil(Double(data.words.count) / Double(wordsPerPage)))
        
        print("📄 PDF布局:")
        print("   - 页面大小: \(pageSize)")
        print("   - 每页单词数: \(wordsPerPage)")
        print("   - 总页数: \(totalPages)")
        
        // 分页生成PDF
        for pageIndex in 0..<totalPages {
            let startIndex = pageIndex * wordsPerPage
            let endIndex = min(startIndex + wordsPerPage, data.words.count)
            let pageWords = Array(data.words[startIndex..<endIndex])
            
            let pageImage = renderer.image { context in
                let cgContext = context.cgContext
                var currentY: CGFloat = 0
                
                // 设置背景色
                cgContext.setFillColor(data.style.backgroundColor.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: pageSize))
                
                currentY = margin
                
                // 绘制页面内容
                currentY = drawHeader(
                    context: cgContext,
                    data: data,
                    pageSize: pageSize,
                    margin: margin,
                    currentPage: pageIndex + 1,
                    totalPages: totalPages,
                    startY: currentY
                )
                
                currentY = drawWordTable(
                    context: cgContext,
                    words: pageWords,
                    data: data,
                    pageSize: pageSize,
                    margin: margin,
                    startY: currentY,
                    startIndex: startIndex
                )
            }
            
            // 将图片转换为PDF页面
            if let pdfPage = PDFPage(image: pageImage) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }
        
        print("✅ PDF生成完成，共 \(pdfDocument.pageCount) 页")
        return pdfDocument
    }
    
    // MARK: - 计算每页单词数
    private func calculateWordsPerPage(pageSize: CGSize, margin: CGFloat) -> Int {
        let availableHeight = pageSize.height - 2 * margin - 120 // 减去标题和页脚空间
        let rowHeight: CGFloat = 40 // 每行高度
        return max(1, Int(availableHeight / rowHeight))
    }
    
    // MARK: - 绘制页面标题
    private func drawHeader(
        context: CGContext,
        data: PDFExportData,
        pageSize: CGSize,
        margin: CGFloat,
        currentPage: Int,
        totalPages: Int,
        startY: CGFloat
    ) -> CGFloat {
        var y = startY
        let contentWidth = pageSize.width - 2 * margin
        
        // 页码（右上角）
        let pageFont = UIFont.systemFont(ofSize: 11)
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: pageFont,
            .foregroundColor: data.style.textColor.withAlphaComponent(0.7)
        ]
        
        let pageText = "第 \(currentPage) 页 / 共 \(totalPages) 页"
        let pageString = NSAttributedString(string: pageText, attributes: pageAttributes)
        let pageSizeRect = pageString.size()
        let pageRect = CGRect(
            x: pageSize.width - margin - pageSizeRect.width,
            y: startY,
            width: pageSizeRect.width,
            height: pageSizeRect.height
        )
        pageString.draw(in: pageRect)
        
        // 主标题（居中显示）
        let titleFont = UIFont.boldSystemFont(ofSize: 22)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: data.style.titleColor
        ]
        
        let titleString = NSAttributedString(string: data.title, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleRect = CGRect(
            x: margin + (contentWidth - titleSize.width) / 2,
            y: y,
            width: titleSize.width,
            height: titleSize.height
        )
        titleString.draw(in: titleRect)
        y += titleSize.height + 8
        
        // 副标题（居中显示）
        let subtitleFont = UIFont.systemFont(ofSize: 14)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: data.style.textColor.withAlphaComponent(0.8)
        ]
        
        let subtitleString = NSAttributedString(string: data.subtitle, attributes: subtitleAttributes)
        let subtitleSize = subtitleString.size()
        let subtitleRect = CGRect(
            x: margin + (contentWidth - subtitleSize.width) / 2,
            y: y,
            width: subtitleSize.width,
            height: subtitleSize.height
        )
        subtitleString.draw(in: subtitleRect)
        y += subtitleSize.height + 25
        
        // 绘制标题下方的装饰线
        context.setStrokeColor(data.style.titleColor.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: margin + contentWidth * 0.2, y: y - 10))
        context.addLine(to: CGPoint(x: margin + contentWidth * 0.8, y: y - 10))
        context.strokePath()
        
        return y
    }
    
    // MARK: - 绘制单词表格
    private func drawWordTable(
        context: CGContext,
        words: [StudyWord],
        data: PDFExportData,
        pageSize: CGSize,
        margin: CGFloat,
        startY: CGFloat,
        startIndex: Int
    ) -> CGFloat {
        var y = startY
        let contentWidth = pageSize.width - 2 * margin
        let rowHeight: CGFloat = 40
        
        // 绘制表格标题行
        y = drawTableHeader(
            context: context,
            data: data,
            x: margin,
            y: y,
            width: contentWidth,
            height: rowHeight
        )
        
        // 绘制单词行
        for (index, word) in words.enumerated() {
            let globalIndex = startIndex + index + 1
            y = drawWordRow(
                context: context,
                word: word,
                data: data,
                x: margin,
                y: y,
                width: contentWidth,
                height: rowHeight,
                index: globalIndex,
                isEvenRow: index % 2 == 0
            )
        }
        
        return y
    }
    
    // MARK: - 绘制表格标题行
    private func drawTableHeader(
        context: CGContext,
        data: PDFExportData,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> CGFloat {
        // 检查是否是错词本导出（是否有错误次数信息）
        let hasErrorCount = data.words.first?.errorCount != nil
        
        let noWidth: CGFloat = 50
        let errorCountWidth: CGFloat = hasErrorCount ? 60 : 0
        let remainingWidth = width - noWidth - errorCountWidth
        let wordWidth = remainingWidth / 2
        let meaningWidth = remainingWidth - wordWidth
        
        // 绘制标题行背景
        context.setFillColor(data.style.headerColor.cgColor)
        context.fill(CGRect(x: x, y: y, width: width, height: height))
        
        // 绘制外边框
        context.setStrokeColor(data.style.headerColor.cgColor)
        context.setLineWidth(1.5)
        context.stroke(CGRect(x: x, y: y, width: width, height: height))
        
        // 绘制内部分隔线
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.0)
        
        // NO. 和 Word 之间的分隔线
        context.move(to: CGPoint(x: x + noWidth, y: y))
        context.addLine(to: CGPoint(x: x + noWidth, y: y + height))
        context.strokePath()
        
        // Word 和 Meaning 之间的分隔线
        context.move(to: CGPoint(x: x + noWidth + wordWidth, y: y))
        context.addLine(to: CGPoint(x: x + noWidth + wordWidth, y: y + height))
        context.strokePath()
        
        // 如果有错误次数列，绘制 Meaning 和 ErrorCount 之间的分隔线
        if hasErrorCount {
            context.move(to: CGPoint(x: x + noWidth + wordWidth + meaningWidth, y: y))
            context.addLine(to: CGPoint(x: x + noWidth + wordWidth + meaningWidth, y: y + height))
            context.strokePath()
        }
        
        let font = UIFont.boldSystemFont(ofSize: 14)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        // NO. 标题（始终显示）
        let noString = NSAttributedString(string: "NO.", attributes: textAttributes)
        let noRect = CGRect(x: x + 10, y: y + (height - noString.size().height) / 2, width: noWidth - 20, height: noString.size().height)
        noString.draw(in: noRect)
        
        // Word 标题（始终显示）
        let wordString = NSAttributedString(string: "Word", attributes: textAttributes)
        let wordRect = CGRect(x: x + noWidth + 10, y: y + (height - wordString.size().height) / 2, width: wordWidth - 20, height: wordString.size().height)
        wordString.draw(in: wordRect)
        
        // Meaning 标题（始终显示）
        let meaningString = NSAttributedString(string: "Meaning", attributes: textAttributes)
        let meaningRect = CGRect(x: x + noWidth + wordWidth + 10, y: y + (height - meaningString.size().height) / 2, width: meaningWidth - 20, height: meaningString.size().height)
        meaningString.draw(in: meaningRect)
        
        // 错误次数标题（仅在错词本导出时显示）
        if hasErrorCount {
            let errorCountString = NSAttributedString(string: "错误次数", attributes: textAttributes)
            let errorCountRect = CGRect(x: x + noWidth + wordWidth + meaningWidth + 10, y: y + (height - errorCountString.size().height) / 2, width: errorCountWidth - 20, height: errorCountString.size().height)
            errorCountString.draw(in: errorCountRect)
        }
        
        return y + height
    }
    
    // MARK: - 绘制单词行
    private func drawWordRow(
        context: CGContext,
        word: StudyWord,
        data: PDFExportData,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        index: Int,
        isEvenRow: Bool
    ) -> CGFloat {
        // 检查是否是错词本导出（是否有错误次数信息）
        let hasErrorCount = word.errorCount != nil
        
        let noWidth: CGFloat = 50
        let errorCountWidth: CGFloat = hasErrorCount ? 60 : 0
        let remainingWidth = width - noWidth - errorCountWidth
        let wordWidth = remainingWidth / 2
        let meaningWidth = remainingWidth - wordWidth
        
        // 绘制行背景（斑马纹）
        if isEvenRow {
            context.setFillColor(data.style.accentColor.cgColor)
            context.fill(CGRect(x: x, y: y, width: width, height: height))
        }
        
        // 绘制外边框
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.8)
        context.stroke(CGRect(x: x, y: y, width: width, height: height))
        
        // 绘制内部分隔线
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        
        // NO. 和 Word 之间的分隔线
        context.move(to: CGPoint(x: x + noWidth, y: y))
        context.addLine(to: CGPoint(x: x + noWidth, y: y + height))
        context.strokePath()
        
        // Word 和 Meaning 之间的分隔线
        context.move(to: CGPoint(x: x + noWidth + wordWidth, y: y))
        context.addLine(to: CGPoint(x: x + noWidth + wordWidth, y: y + height))
        context.strokePath()
        
        // 如果有错误次数列，绘制 Meaning 和 ErrorCount 之间的分隔线
        if hasErrorCount {
            context.move(to: CGPoint(x: x + noWidth + wordWidth + meaningWidth, y: y))
            context.addLine(to: CGPoint(x: x + noWidth + wordWidth + meaningWidth, y: y + height))
            context.strokePath()
        }
        
        let font = UIFont.systemFont(ofSize: 12)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: data.style.textColor
        ]
        
        // 序号
        let indexString = NSAttributedString(string: "\(index)", attributes: textAttributes)
        let indexRect = CGRect(x: x + 10, y: y + (height - indexString.size().height) / 2, width: noWidth - 20, height: indexString.size().height)
        indexString.draw(in: indexRect)
        
        // 根据模式显示不同内容
        switch data.mode {
        case .chineseEnglish:
            // 显示英文单词
            let wordString = NSAttributedString(string: word.word, attributes: textAttributes)
            let wordRect = CGRect(x: x + noWidth + 10, y: y + (height - wordString.size().height) / 2, width: wordWidth - 20, height: wordString.size().height)
            wordString.draw(in: wordRect)
            
            // 显示中文释义
            let meaningString = NSAttributedString(string: word.meaning, attributes: textAttributes)
            let meaningRect = CGRect(x: x + noWidth + wordWidth + 10, y: y + (height - meaningString.size().height) / 2, width: meaningWidth - 20, height: meaningString.size().height)
            meaningString.draw(in: meaningRect)
            
        case .dictationMeaning:
            // 只在Word列显示英文单词
            let wordString = NSAttributedString(string: word.word, attributes: textAttributes)
            let wordRect = CGRect(x: x + noWidth + 10, y: y + (height - wordString.size().height) / 2, width: wordWidth - 20, height: wordString.size().height)
            wordString.draw(in: wordRect)
            
        case .dictationWord:
            // 只在Meaning列显示中文释义
            let meaningString = NSAttributedString(string: word.meaning, attributes: textAttributes)
            let meaningRect = CGRect(x: x + noWidth + wordWidth + 10, y: y + (height - meaningString.size().height) / 2, width: meaningWidth - 20, height: meaningString.size().height)
            meaningString.draw(in: meaningRect)
        }
        
        // 绘制错误次数（仅在错词本导出时）
        if hasErrorCount, let errorCount = word.errorCount {
            let errorCountString = NSAttributedString(string: "\(errorCount)", attributes: textAttributes)
            let errorCountRect = CGRect(x: x + noWidth + wordWidth + meaningWidth + 10, y: y + (height - errorCountString.size().height) / 2, width: errorCountWidth - 20, height: errorCountString.size().height)
            errorCountString.draw(in: errorCountRect)
        }
        
        return y + height
    }
    
    // MARK: - 保存PDF到文件
    func savePDF(_ pdfDocument: PDFDocument, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsPath.appendingPathComponent("\(filename).pdf")
        
        if pdfDocument.write(to: pdfURL) {
            print("✅ PDF已保存到: \(pdfURL)")
            return pdfURL
        } else {
            print("❌ PDF保存失败")
            return nil
        }
    }
    
    // MARK: - 分享PDF
    func sharePDF(_ pdfDocument: PDFDocument, filename: String, from viewController: UIViewController) {
        guard let pdfURL = savePDF(pdfDocument, filename: filename) else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        
        // iPad支持
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
}
