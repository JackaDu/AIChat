# Appwrite Integration Guide for iOS English Learning App

## Overview
This guide provides step-by-step instructions for integrating Appwrite into your iOS English learning app to store user-related data.

## Prerequisites
- Appwrite Cloud account or self-hosted Appwrite instance
- iOS project with SwiftUI
- Xcode 15.0+
- iOS 15.0+

## 1. Appwrite Setup

### 1.1 Create Appwrite Project
1. Go to [Appwrite Cloud](https://cloud.appwrite.io) or your self-hosted instance
2. Create a new project: "English Learning App"
3. Note down your Project ID and API Endpoint

### 1.2 Configure Authentication
1. Enable Email/Password authentication
2. Configure OAuth providers if needed (Google, Apple, etc.)
3. Set up email templates for verification

### 1.3 Create Database and Collections
Follow the database schema from `Appwrite_Database_Schema.md` to create:
- Database: `english_learning`
- Collections: `users`, `user_preferences`, `wrong_words`, `study_sessions`, `study_words`, `learning_progress`, `word_attempts`, `user_achievements`

## 2. iOS Integration

### 2.1 Add Appwrite SDK
Add to your `Package.swift` or through Xcode Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/appwrite/sdk-for-swift", from: "4.0.0")
]
```

### 2.2 Create Appwrite Configuration
Create `AppwriteConfig.swift`:

```swift
import Foundation
import Appwrite

class AppwriteConfig {
    static let shared = AppwriteConfig()
    
    private init() {}
    
    // Replace with your actual values
    let endpoint = "https://cloud.appwrite.io/v1"
    let projectId = "your-project-id"
    let databaseId = "english_learning"
    
    // Collection IDs
    let usersCollectionId = "users"
    let userPreferencesCollectionId = "user_preferences"
    let wrongWordsCollectionId = "wrong_words"
    let studySessionsCollectionId = "study_sessions"
    let studyWordsCollectionId = "study_words"
    let learningProgressCollectionId = "learning_progress"
    let wordAttemptsCollectionId = "word_attempts"
    let userAchievementsCollectionId = "user_achievements"
    
    func getClient() -> Client {
        let client = Client()
        client
            .setEndpoint(endpoint)
            .setProject(projectId)
        return client
    }
}
```

### 2.3 Create Appwrite Service
Create `AppwriteService.swift`:

```swift
import Foundation
import Appwrite
import AppwriteModels

@MainActor
class AppwriteService: ObservableObject {
    private let client: Client
    private let account: Account
    private let databases: Databases
    
    @Published var isAuthenticated = false
    @Published var currentUser: User<[String: AnyCodable]>?
    
    init() {
        self.client = AppwriteConfig.shared.getClient()
        self.account = Account(client)
        self.databases = Databases(client)
        
        // Check if user is already logged in
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, name: String) async throws {
        do {
            let user = try await account.create(
                userId: ID.unique(),
                email: email,
                password: password,
                name: name
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            
            // Create user preferences
            try await createUserPreferences(userId: user.id)
            
        } catch {
            print("Sign up error: \(error)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let session = try await account.createEmailPasswordSession(
                email: email,
                password: password
            )
            
            let user = try await account.get()
            self.currentUser = user
            self.isAuthenticated = true
            
        } catch {
            print("Sign in error: \(error)")
            throw error
        }
    }
    
    func signOut() async throws {
        try await account.deleteSession(sessionId: "current")
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    private func checkAuthStatus() async {
        do {
            let user = try await account.get()
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
        }
    }
    
    // MARK: - User Preferences
    
    func createUserPreferences(userId: String) async throws {
        let preferences = UserPreferences(
            selectedGrade: .high1,
            selectedVocabularyType: .daily,
            selectedTextbookVersion: .renjiao,
            selectedCourseType: .required,
            selectedRequiredCourse: .book1,
            selectedElectiveCourse: .book1,
            selectedUnits: [.unit1],
            isFirstLaunch: true,
            dailyStudyAmount: .ten,
            hasSelectedStudyAmount: false,
            defaultLearningMode: .recognizeMeaning
        )
        
        let data: [String: AnyCodable] = [
            "userId": AnyCodable(userId),
            "grade": AnyCodable(preferences.selectedGrade.rawValue),
            "vocabularyType": AnyCodable(preferences.selectedVocabularyType.rawValue),
            "textbookVersion": AnyCodable(preferences.selectedTextbookVersion.rawValue),
            "courseType": AnyCodable(preferences.selectedCourseType.rawValue),
            "requiredCourse": AnyCodable(preferences.selectedRequiredCourse.rawValue),
            "electiveCourse": AnyCodable(preferences.selectedElectiveCourse.rawValue),
            "selectedUnits": AnyCodable(preferences.selectedUnits.map { $0.rawValue }),
            "dailyStudyAmount": AnyCodable(preferences.dailyStudyAmount.rawValue),
            "defaultLearningMode": AnyCodable(preferences.defaultLearningMode.rawValue),
            "isFirstLaunch": AnyCodable(preferences.isFirstLaunch),
            "hasSelectedStudyAmount": AnyCodable(preferences.hasSelectedStudyAmount),
            "updatedAt": AnyCodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await databases.createDocument(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.userPreferencesCollectionId,
            documentId: userId,
            data: data
        )
    }
    
    func getUserPreferences(userId: String) async throws -> UserPreferences? {
        do {
            let document = try await databases.getDocument(
                databaseId: AppwriteConfig.shared.databaseId,
                collectionId: AppwriteConfig.shared.userPreferencesCollectionId,
                documentId: userId
            )
            
            return try parseUserPreferences(from: document.data)
        } catch {
            print("Error fetching user preferences: \(error)")
            return nil
        }
    }
    
    func updateUserPreferences(userId: String, preferences: UserPreferences) async throws {
        let data: [String: AnyCodable] = [
            "grade": AnyCodable(preferences.selectedGrade.rawValue),
            "vocabularyType": AnyCodable(preferences.selectedVocabularyType.rawValue),
            "textbookVersion": AnyCodable(preferences.selectedTextbookVersion.rawValue),
            "courseType": AnyCodable(preferences.selectedCourseType.rawValue),
            "requiredCourse": AnyCodable(preferences.selectedRequiredCourse.rawValue),
            "electiveCourse": AnyCodable(preferences.selectedElectiveCourse.rawValue),
            "selectedUnits": AnyCodable(preferences.selectedUnits.map { $0.rawValue }),
            "dailyStudyAmount": AnyCodable(preferences.dailyStudyAmount.rawValue),
            "defaultLearningMode": AnyCodable(preferences.defaultLearningMode.rawValue),
            "isFirstLaunch": AnyCodable(preferences.isFirstLaunch),
            "hasSelectedStudyAmount": AnyCodable(preferences.hasSelectedStudyAmount),
            "updatedAt": AnyCodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await databases.updateDocument(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.userPreferencesCollectionId,
            documentId: userId,
            data: data
        )
    }
    
    // MARK: - Wrong Words
    
    func addWrongWord(userId: String, wrongWord: WrongWord) async throws {
        let data: [String: AnyCodable] = [
            "userId": AnyCodable(userId),
            "word": AnyCodable(wrongWord.word),
            "meaning": AnyCodable(wrongWord.meaning),
            "context": AnyCodable(wrongWord.context),
            "learningDirection": AnyCodable(wrongWord.learningDirection.rawValue),
            "dateAdded": AnyCodable(ISO8601DateFormatter().string(from: wrongWord.dateAdded)),
            "reviewDates": AnyCodable(wrongWord.reviewDates.map { ISO8601DateFormatter().string(from: $0) }),
            "nextReviewDate": AnyCodable(ISO8601DateFormatter().string(from: wrongWord.nextReviewDate)),
            "reviewCount": AnyCodable(wrongWord.reviewCount),
            "isMastered": AnyCodable(wrongWord.isMastered),
            "errorCount": AnyCodable(wrongWord.errorCount),
            "totalAttempts": AnyCodable(wrongWord.totalAttempts),
            "textbookSource": AnyCodable(encodeTextbookSource(wrongWord.textbookSource)),
            "partOfSpeech": AnyCodable(wrongWord.partOfSpeech?.rawValue),
            "examSource": AnyCodable(wrongWord.examSource?.rawValue),
            "difficulty": AnyCodable(wrongWord.difficulty.rawValue),
            "lastReviewDate": AnyCodable(wrongWord.lastReviewDate?.description),
            "consecutiveCorrect": AnyCodable(wrongWord.consecutiveCorrect),
            "consecutiveWrong": AnyCodable(wrongWord.consecutiveWrong),
            "errorRate": AnyCodable(wrongWord.errorRate)
        ]
        
        try await databases.createDocument(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.wrongWordsCollectionId,
            documentId: ID.unique(),
            data: data
        )
    }
    
    func getWrongWords(userId: String) async throws -> [WrongWord] {
        let documents = try await databases.listDocuments(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.wrongWordsCollectionId,
            queries: [
                Query.equal("userId", value: userId)
            ]
        )
        
        return documents.documents.compactMap { document in
            parseWrongWord(from: document.data)
        }
    }
    
    func updateWrongWord(documentId: String, wrongWord: WrongWord) async throws {
        let data: [String: AnyCodable] = [
            "reviewDates": AnyCodable(wrongWord.reviewDates.map { ISO8601DateFormatter().string(from: $0) }),
            "nextReviewDate": AnyCodable(ISO8601DateFormatter().string(from: wrongWord.nextReviewDate)),
            "reviewCount": AnyCodable(wrongWord.reviewCount),
            "isMastered": AnyCodable(wrongWord.isMastered),
            "errorCount": AnyCodable(wrongWord.errorCount),
            "totalAttempts": AnyCodable(wrongWord.totalAttempts),
            "lastReviewDate": AnyCodable(wrongWord.lastReviewDate?.description),
            "consecutiveCorrect": AnyCodable(wrongWord.consecutiveCorrect),
            "consecutiveWrong": AnyCodable(wrongWord.consecutiveWrong),
            "errorRate": AnyCodable(wrongWord.errorRate)
        ]
        
        try await databases.updateDocument(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.wrongWordsCollectionId,
            documentId: documentId,
            data: data
        )
    }
    
    // MARK: - Study Sessions
    
    func createStudySession(userId: String, sessionType: String, learningMode: LearningDirection) async throws -> String {
        let sessionId = ID.unique()
        let startTime = Date()
        
        let data: [String: AnyCodable] = [
            "userId": AnyCodable(userId),
            "sessionId": AnyCodable(sessionId),
            "sessionType": AnyCodable(sessionType),
            "learningMode": AnyCodable(learningMode.rawValue),
            "startTime": AnyCodable(ISO8601DateFormatter().string(from: startTime)),
            "duration": AnyCodable(0),
            "wordsStudied": AnyCodable(0),
            "correctAnswers": AnyCodable(0),
            "wrongAnswers": AnyCodable(0),
            "accuracy": AnyCodable(0.0),
            "words": AnyCodable([]),
            "completed": AnyCodable(false),
            "interrupted": AnyCodable(false)
        ]
        
        try await databases.createDocument(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.studySessionsCollectionId,
            documentId: sessionId,
            data: data
        )
        
        return sessionId
    }
    
    func updateStudySession(sessionId: String, endTime: Date, wordsStudied: Int, correctAnswers: Int, wrongAnswers: Int, words: [String]) async throws {
        let duration = Int(endTime.timeIntervalSinceNow)
        let accuracy = wordsStudied > 0 ? Double(correctAnswers) / Double(wordsStudied) : 0.0
        
        let data: [String: AnyCodable] = [
            "endTime": AnyCodable(ISO8601DateFormatter().string(from: endTime)),
            "duration": AnyCodable(duration),
            "wordsStudied": AnyCodable(wordsStudied),
            "correctAnswers": AnyCodable(correctAnswers),
            "wrongAnswers": AnyCodable(wrongAnswers),
            "accuracy": AnyCodable(accuracy),
            "words": AnyCodable(words),
            "completed": AnyCodable(true)
        ]
        
        try await databases.updateDocument(
            databaseId: AppwriteConfig.shared.databaseId,
            collectionId: AppwriteConfig.shared.studySessionsCollectionId,
            documentId: sessionId,
            data: data
        )
    }
    
    // MARK: - Helper Methods
    
    private func parseUserPreferences(from data: [String: AnyCodable]) -> UserPreferences? {
        // Implementation to parse UserPreferences from Appwrite document
        // This would convert the stored data back to your UserPreferences struct
        return nil // Placeholder
    }
    
    private func parseWrongWord(from data: [String: AnyCodable]) -> WrongWord? {
        // Implementation to parse WrongWord from Appwrite document
        return nil // Placeholder
    }
    
    private func encodeTextbookSource(_ source: TextbookSource?) -> [String: AnyCodable]? {
        guard let source = source else { return nil }
        return [
            "textbookVersion": AnyCodable(source.textbookVersion.rawValue),
            "courseBook": AnyCodable(source.courseBook),
            "unit": AnyCodable(source.unit.shortName)
        ]
    }
}
```

### 2.4 Update UserPreferencesManager
Modify your existing `UserPreferencesManager.swift` to integrate with Appwrite:

```swift
import Foundation
import SwiftUI

@MainActor
class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences {
        didSet {
            savePreferences()
        }
    }
    
    private let appwriteService = AppwriteService()
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "UserPreferences"
    
    init() {
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
                // Merge with local preferences (cloud takes precedence)
                self.userPreferences = cloudPreferences
            } else {
                // Upload local preferences to cloud
                try await appwriteService.updateUserPreferences(userId: userId, preferences: userPreferences)
            }
        } catch {
            print("Failed to sync preferences with Appwrite: \(error)")
        }
    }
    
    // ... rest of your existing methods
}
```

### 2.5 Update WrongWordManager
Modify your existing `WrongWordManager.swift` to integrate with Appwrite:

```swift
import Foundation
import SwiftUI

@MainActor
class WrongWordManager: ObservableObject {
    @Published var wrongWords: [WrongWord] = []
    
    private let appwriteService = AppwriteService()
    private let userDefaults = UserDefaults.standard
    private let wrongWordsKey = "WrongWords"
    
    init() {
        loadWrongWords()
        
        // Sync with Appwrite if authenticated
        Task {
            await syncWithAppwrite()
        }
    }
    
    private func loadWrongWords() {
        if let data = userDefaults.data(forKey: wrongWordsKey),
           let words = try? JSONDecoder().decode([WrongWord].self, from: data) {
            self.wrongWords = words
        }
    }
    
    private func saveWrongWords() {
        if let data = try? JSONEncoder().encode(wrongWords) {
            userDefaults.set(data, forKey: wrongWordsKey)
        }
    }
    
    private func syncWithAppwrite() async {
        guard appwriteService.isAuthenticated,
              let userId = appwriteService.currentUser?.id else {
            return
        }
        
        do {
            let cloudWords = try await appwriteService.getWrongWords(userId: userId)
            
            // Merge local and cloud data
            let localWordIds = Set(wrongWords.map { $0.id })
            let cloudWordIds = Set(cloudWords.map { $0.id })
            
            // Add new words from cloud
            let newWords = cloudWords.filter { !localWordIds.contains($0.id) }
            wrongWords.append(contentsOf: newWords)
            
            // Update existing words from cloud
            for cloudWord in cloudWords {
                if let index = wrongWords.firstIndex(where: { $0.id == cloudWord.id }) {
                    wrongWords[index] = cloudWord
                }
            }
            
            // Upload local words that don't exist in cloud
            let localOnlyWords = wrongWords.filter { !cloudWordIds.contains($0.id) }
            for word in localOnlyWords {
                try await appwriteService.addWrongWord(userId: userId, wrongWord: word)
            }
            
            saveWrongWords()
        } catch {
            print("Failed to sync wrong words with Appwrite: \(error)")
        }
    }
    
    func addWrongWord(_ word: WrongWord) {
        wrongWords.append(word)
        saveWrongWords()
        
        // Sync with Appwrite
        Task {
            guard appwriteService.isAuthenticated,
                  let userId = appwriteService.currentUser?.id else {
                return
            }
            
            do {
                try await appwriteService.addWrongWord(userId: userId, wrongWord: word)
            } catch {
                print("Failed to add wrong word to Appwrite: \(error)")
            }
        }
    }
    
    // ... rest of your existing methods
}
```

## 3. Authentication Flow

### 3.1 Create Authentication View
Create `AuthenticationView.swift`:

```swift
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var appwriteService = AppwriteService()
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("English Learning App")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: {
                    Task {
                        await handleAuthentication()
                    }
                }) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleAuthentication() async {
        do {
            if isSignUp {
                try await appwriteService.signUp(email: email, password: password, name: name)
            } else {
                try await appwriteService.signIn(email: email, password: password)
            }
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
```

### 3.2 Update RootTabView
Modify your `RootTabView.swift` to handle authentication:

```swift
import SwiftUI

struct RootTabView: View {
    @StateObject private var appwriteService = AppwriteService()
    @StateObject private var preferencesManager = UserPreferencesManager()
    @StateObject private var wrongWordManager = WrongWordManager()
    
    var body: some View {
        Group {
            if appwriteService.isAuthenticated {
                MainTabView()
                    .environmentObject(preferencesManager)
                    .environmentObject(wrongWordManager)
            } else {
                AuthenticationView()
            }
        }
    }
}
```

## 4. Data Synchronization

### 4.1 Create Sync Manager
Create `DataSyncManager.swift`:

```swift
import Foundation
import SwiftUI

@MainActor
class DataSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let appwriteService = AppwriteService()
    
    func syncAllData() async {
        guard appwriteService.isAuthenticated else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Sync user preferences
            // Sync wrong words
            // Sync study sessions
            // Sync learning progress
            
            lastSyncDate = Date()
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    func syncInBackground() {
        Task {
            await syncAllData()
        }
    }
}
```

## 5. Error Handling and Offline Support

### 5.1 Create Error Types
```swift
enum AppwriteError: LocalizedError {
    case networkError
    case authenticationError
    case dataSyncError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .authenticationError:
            return "Authentication failed. Please sign in again."
        case .dataSyncError:
            return "Failed to sync data. Your data will be synced when connection is restored."
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
}
```

### 5.2 Implement Offline Queue
Create `OfflineQueue.swift`:

```swift
import Foundation

class OfflineQueue {
    static let shared = OfflineQueue()
    private let queue = DispatchQueue(label: "offline.queue", qos: .background)
    private var pendingOperations: [() async throws -> Void] = []
    
    private init() {}
    
    func addOperation(_ operation: @escaping () async throws -> Void) {
        queue.async {
            self.pendingOperations.append(operation)
        }
    }
    
    func processQueue() async {
        let operations = pendingOperations
        pendingOperations.removeAll()
        
        for operation in operations {
            do {
                try await operation()
            } catch {
                // Re-queue failed operations
                pendingOperations.append(operation)
            }
        }
    }
}
```

## 6. Testing and Deployment

### 6.1 Test Data Migration
Create a migration script to move existing UserDefaults data to Appwrite:

```swift
class DataMigrationManager {
    static func migrateToAppwrite() async {
        // Migrate user preferences
        // Migrate wrong words
        // Migrate study sessions
        // Clean up old UserDefaults data
    }
}
```

### 6.2 Performance Monitoring
Add performance monitoring to track sync times and error rates:

```swift
class PerformanceMonitor {
    static func trackSyncTime<T>(_ operation: () async throws -> T) async throws -> T {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        
        print("Operation completed in \(duration) seconds")
        return result
    }
}
```

This integration guide provides a comprehensive approach to storing user-related data in Appwrite while maintaining offline functionality and smooth user experience.
