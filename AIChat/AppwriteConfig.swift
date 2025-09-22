import Foundation
// import Appwrite  // Temporarily commented out until SDK is properly linked

// MARK: - Appwrite Configuration
class AppwriteConfig {
    static let shared = AppwriteConfig()
    
    // MARK: - Appwrite Settings
    let endpoint: String
    let projectId: String
    let serverAPIKey: String
    let databaseId = "english_learning"
    
    // MARK: - Collection IDs (English names)
    let usersCollectionId = "users"
    let userPreferencesCollectionId = "user_preferences"
    let wrongWordsCollectionId = "wrong_words"
    let studyRecordsCollectionId = "study_records"
    let studySessionsCollectionId = "study_sessions"
    let studyWordsCollectionId = "study_words"
    let learningProgressCollectionId = "learning_progress"
    let wordAttemptsCollectionId = "word_attempts"
    let userAchievementsCollectionId = "user_achievements"
    
    // MARK: - Client Configuration
    // Temporarily commented out until SDK is properly linked
    /*
    func getClient() -> Client {
        let client = Client()
        client
            .setEndpoint(endpoint)
            .setProject(projectId)
        return client
    }
    */
    
    // MARK: - Environment Configuration
    var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    // MARK: - API Keys (if needed for server-side operations)
    private init() {
        // Load configuration from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found or invalid format")
        }
        
        self.endpoint = plist["APPWRITE_PUBLIC_ENDPOINT"] as? String ?? "https://cloud.appwrite.io/v1"
        self.projectId = plist["APPWRITE_PROJECT_ID"] as? String ?? ""
        self.serverAPIKey = plist["APPWRITE_SERVER_API_KEY"] as? String ?? ""
    }
}
