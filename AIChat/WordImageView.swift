import SwiftUI

// MARK: - 单词图片显示组件
struct WordImageView: View {
    let imageURL: String?
    let word: String
    @State private var isLoading = false
    @State private var imageError = false
    @State private var showingFullScreen = false
    
    var body: some View {
        if let imageURL = imageURL, !imageURL.isEmpty {
            Button(action: {
                print("🖼️ WordImageView: 点击图片 \(word), URL: \(imageURL)")
                showingFullScreen = true
            }) {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    VStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(1.0)
                        Text("加载中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $showingFullScreen) {
                FullScreenImageView(imageURL: imageURL, word: word)
            }
            .onAppear {
                print("🖼️ WordImageView出现: \(word), imageURL: \(imageURL)")
            }
        } else {
            // 没有图片时显示占位符
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.08))
                .frame(width: 100, height: 100)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary.opacity(0.6))
                        
                        Text("暂无图片")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - 全屏图片显示
struct FullScreenImageView: View {
    let imageURL: String
    let word: String
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                            )
                        )
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                
                VStack {
                    Spacer()
                    Text("\(word) - 相关图片")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - 记忆辅助信息显示组件
struct MemoryAidView: View {
    let etymology: String?
    let memoryTip: String?
    let relatedWords: [String]?
    let example: String? // 新增例句参数
    @State private var showingDetails = false
    
    var body: some View {
        if etymology != nil || memoryTip != nil || relatedWords != nil || (example != nil && !example!.isEmpty) {
            Button(action: {
                showingDetails = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Text("记忆辅助")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingDetails) {
                MemoryAidDetailView(
                    etymology: etymology,
                    memoryTip: memoryTip,
                    relatedWords: relatedWords,
                    example: example
                )
            }
        }
    }
}

// MARK: - 记忆辅助详情页面
struct MemoryAidDetailView: View {
    let etymology: String?
    let memoryTip: String?
    let relatedWords: [String]?
    let example: String? // 新增例句参数
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 记忆技巧 - 放在最前面
                    if let memoryTip = memoryTip, !memoryTip.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("记忆技巧")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(memoryTip)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // 词源信息 - 放在记忆技巧后面
                    if let etymology = etymology, !etymology.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("词源")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(etymology)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .background(.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    if let relatedWords = relatedWords, !relatedWords.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("相关单词")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(relatedWords, id: \.self) { word in
                                    Text(word)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.purple.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                    
                    // 例句显示 - 使用优化的例句显示
                    if let example = example, !example.isEmpty {
                        MemoryAidExampleView(exampleText: example)
                    }
                }
                .padding()
            }
            .navigationTitle("记忆辅助")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WordImageView(
            imageURL: "https://example.com/image.jpg",
            word: "apple"
        )
        
        MemoryAidView(
            etymology: "来自古英语 æppel",
            memoryTip: "想象一个红色的苹果",
            relatedWords: ["fruit", "red", "tree"],
            example: "I eat an apple every day."
        )
    }
    .padding()
}

// MARK: - 记忆辅助页面的例句显示组件
struct MemoryAidExampleView: View {
    let exampleText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text("例句")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            if let examples = parseExamples(from: exampleText), !examples.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(.blue)
                                    .clipShape(Circle())
                                
                                Text("例句 \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(example.english)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .lineSpacing(2)
                                
                                Text(example.chinese)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .italic()
                                    .lineSpacing(2)
                            }
                        }
                        .padding(12)
                        .background(.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            } else {
                // 如果解析失败，显示格式化的原始文本
                Text(formatRawExample(exampleText))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .padding(12)
                    .background(.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(.blue.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.15), lineWidth: 1)
        )
    }
    
    // 解析JSON格式的例句
    private func parseExamples(from text: String) -> [(english: String, chinese: String)]? {
        // 尝试解析JSON格式
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                var examples: [(english: String, chinese: String)] = []
                
                for item in jsonArray {
                    let english = item["english"] as? String ?? item["en"] as? String ?? ""
                    let chinese = item["chinese"] as? String ?? item["zh"] as? String ?? item["translation"] as? String ?? ""
                    
                    if !english.isEmpty || !chinese.isEmpty {
                        examples.append((english: english, chinese: chinese))
                    }
                }
                
                return examples.isEmpty ? nil : examples
            }
        } catch {
            print("JSON解析失败: \(error)")
        }
        
        return nil
    }
    
    // 格式化原始例句文本
    private func formatRawExample(_ text: String) -> String {
        // 移除JSON格式的括号和引号
        var formatted = text
            .replacingOccurrences(of: "[{", with: "")
            .replacingOccurrences(of: "}]", with: "")
            .replacingOccurrences(of: "},{", with: "\n\n")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "english:", with: "🇺🇸 ")
            .replacingOccurrences(of: "chinese:", with: "🇨🇳 ")
            .replacingOccurrences(of: "en:", with: "🇺🇸 ")
            .replacingOccurrences(of: "zh:", with: "🇨🇳 ")
            .replacingOccurrences(of: "translation:", with: "🇨🇳 ")
        
        // 清理多余的空格和换行
        let lines = formatted.components(separatedBy: .newlines)
        let cleanedLines = lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        return cleanedLines.joined(separator: "\n")
    }
}
