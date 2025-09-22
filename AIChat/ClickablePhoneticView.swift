import SwiftUI

// MARK: - 可点击音标显示组件
struct ClickablePhoneticView: View {
    let word: String
    @EnvironmentObject var phoneticService: PhoneticService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @State private var phonetic: String?
    @State private var currentPronunciationType: PronunciationType
    let font: Font
    
    init(word: String, font: Font = .caption) {
        self.word = word
        self.font = font
        self._currentPronunciationType = State(initialValue: .american)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // 可点击的国旗按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentPronunciationType = phoneticService.togglePronunciationType(currentType: currentPronunciationType)
                    preferencesManager.userPreferences.pronunciationType = currentPronunciationType
                    // UserPreferencesManager会自动保存更改
                    loadPhonetic()
                }
                
                // 播放新发音
                phoneticService.playPronunciation(for: word, pronunciationType: currentPronunciationType) {}
            }) {
                Text(currentPronunciationType.emoji)
                    .font(font)
                    .scaleEffect(1.2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 音标文本
            if let phonetic = phonetic {
                Text("[\(phonetic)]")
                    .font(font)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            currentPronunciationType = preferencesManager.userPreferences.pronunciationType
            loadPhonetic()
        }
        .onChange(of: preferencesManager.userPreferences.pronunciationType) { _, newType in
            currentPronunciationType = newType
            loadPhonetic()
        }
    }
    
    private func loadPhonetic() {
        phonetic = phoneticService.getPhoneticSymbol(for: word, pronunciationType: currentPronunciationType)
    }
}

#Preview {
    VStack {
        ClickablePhoneticView(word: "hello")
        
        ClickablePhoneticView(word: "world", font: .title3)
    }
    .environmentObject(PhoneticService())
    .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}
