import Foundation
import SwiftUI

@MainActor
class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences {
        didSet {
            savePreferences()
        }
    }
    
    private let appwriteService: AppwriteService
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "UserPreferences"
    
    init(appwriteService: AppwriteService) {
        self.appwriteService = appwriteService
        // Load from UserDefaults first (for offline support)
        if let data = userDefaults.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        } else {
            self.userPreferences = UserPreferences()
        }
        
        // Sync with Appwrite if authenticated
        Task {
            await syncWithAppwrite()
        }
    }
    
    private func savePreferences() {
        // Save to UserDefaults for offline support
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }
        
        // 同步ThemeManager
        ThemeManager.shared.syncWithUserPreferences(userPreferences)
        
        // Sync with Appwrite if authenticated
        Task {
            await syncWithAppwrite()
        }
    }
    
    private func syncWithAppwrite() async {
        guard appwriteService.isAuthenticated,
              let userId = appwriteService.currentUser?.id else {
            return
        }
        
        do {
            // Try to get preferences from Appwrite
            if let cloudPreferences = try await appwriteService.getUserPreferences(userId: userId) {
                // 智能合并：保留本地的重要设置（如夜间模式），合并云端设置
                var mergedPreferences = cloudPreferences
                
                // 保留本地的夜间模式设置（如果用户刚刚修改过）
                let currentNightMode = self.userPreferences.isNightMode
                if currentNightMode != cloudPreferences.isNightMode {
                    // 如果本地和云端不一致，以本地为准（用户刚刚修改的）
                    mergedPreferences.isNightMode = currentNightMode
                    print("🌙 保留本地夜间模式设置: \(currentNightMode)")
                }
                
                self.userPreferences = mergedPreferences
                
                // 同步ThemeManager
                ThemeManager.shared.syncWithUserPreferences(self.userPreferences)
            } else {
                // Upload local preferences to cloud
                try await appwriteService.updateUserPreferences(userId: userId, preferences: userPreferences)
            }
        } catch {
            print("Failed to sync preferences with Appwrite: \(error)")
        }
    }
    
    func resetPreferences() {
        userPreferences = UserPreferences()
    }
    
    func updateGrade(_ grade: Grade) {
        userPreferences.selectedGrade = grade
    }
    
    func updateVocabularyType(_ type: VocabularyType) {
        userPreferences.selectedVocabularyType = type
    }
    
    func updateDailyStudyAmount(_ amount: DailyStudyAmount) {
        userPreferences.dailyStudyAmount = amount
        userPreferences.hasSelectedStudyAmount = true
    }
    
    func needsStudyAmountSelection() -> Bool {
        return !userPreferences.hasSelectedStudyAmount
    }
    
    // MARK: - 更新用户偏好设置
    @MainActor
    func updateUserPreferences(_ newPreferences: UserPreferences) async {
        self.userPreferences = newPreferences
        savePreferences()
        
        // 同步到 Appwrite 数据库
        await syncWithAppwrite()
    }
    
    // MARK: - 更新用户个人资料
    @MainActor
    func updateUserProfile(nickname: String, avatar: String, avatarColor: String) async {
        var updatedPreferences = userPreferences
        updatedPreferences.userNickname = nickname
        updatedPreferences.userAvatar = avatar
        updatedPreferences.userAvatarColor = avatarColor
        
        await updateUserPreferences(updatedPreferences)
    }
}
