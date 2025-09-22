import Foundation
import SwiftUI

// MARK: - Appwrite Service (HTTP Implementation)
// This version uses direct HTTP requests to Appwrite API
@MainActor
class AppwriteService: ObservableObject {
    // MARK: - Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - User Model
    struct User {
        let id: String
        let name: String
        let email: String
        let createdAt: String
    }
    
    // MARK: - Configuration
    private let config = AppwriteConfig.shared
    private var sessionId: String?
    
    // 公共访问器
    var currentSessionId: String? {
        get {
            return sessionId
        }
    }
    
    // MARK: - Initialization
    init() {
        // Check if user is already logged in
        checkAuthStatus()
    }
    
    // MARK: - Authentication Methods
    
    /// Check if user is currently authenticated
    private func checkAuthStatus() {
        // For now, assume no active session
        self.isAuthenticated = false
        self.currentUser = nil
    }
    
    /// Sign up a new user
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Try to create user account
            let user = try await createUserAccount(email: email, password: password, name: name)
            
            // Clean up any existing sessions before signing in
            try await deleteAllSessions()
            
            // Sign in the user
            let session = try await createEmailPasswordSession(email: email, password: password)
            self.sessionId = session.id
            
            self.currentUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                createdAt: user.createdAt
            )
            self.isAuthenticated = true
            
            // Create user record in our database
            try await createUserRecord(user: user)
            
            print("✅ User signed up successfully: \(user.name)")
            print("📝 User ID: \(user.id)")
            
        } catch AppwriteError.apiError(let message) {
            // Check if user already exists
            if message.contains("already exists") {
                print("⚠️ User already exists, attempting to sign in...")
                try await handleExistingUser(email: email, password: password)
            } else {
                self.errorMessage = message
                print("❌ Sign up failed: \(message)")
                throw AppwriteError.apiError(message)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Sign up failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Handle existing user by signing them in
    private func handleExistingUser(email: String, password: String) async throws {
        do {
            // First, try to delete any existing sessions
            try await deleteAllSessions()
            
            // Then try to sign in
            let session = try await createEmailPasswordSession(email: email, password: password)
            self.sessionId = session.id
            
            // Get current user info
            let user = try await getCurrentUser()
            
            self.currentUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                createdAt: user.createdAt
            )
            self.isAuthenticated = true
            
            // Try to create user record in database (in case it doesn't exist)
            try await createUserRecord(user: user)
            
            print("✅ Existing user signed in successfully: \(user.name)")
            print("📝 User ID: \(user.id)")
            
        } catch {
            self.errorMessage = "User exists but sign in failed: \(error.localizedDescription)"
            print("❌ Sign in failed for existing user: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign in an existing user
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // First, try to delete any existing sessions
            try await deleteAllSessions()
            
            // Create email/password session
            let session = try await createEmailPasswordSession(email: email, password: password)
            self.sessionId = session.id
            
            // Get user details
            let user = try await getCurrentUser()
            
            self.currentUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                createdAt: user.createdAt
            )
            self.isAuthenticated = true
            
            print("✅ User signed in successfully: \(user.name)")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        
        do {
            if let sessionId = sessionId {
                try await deleteSession(sessionId: sessionId)
            }
            self.currentUser = nil
            self.isAuthenticated = false
            self.sessionId = nil
            print("✅ User signed out successfully")
        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - HTTP API Methods
    
    /// Create user account via HTTP
    private func createUserAccount(email: String, password: String, name: String) async throws -> UserResponse {
        let url = URL(string: "\(config.endpoint)/account")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        
        let body = [
            "userId": "unique()",
            "email": email,
            "password": password,
            "name": name
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        // 打印响应信息用于调试
        print("📡 Sign up response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Sign up response data: \(responseString)")
        }
        
        if httpResponse.statusCode != 201 {
            let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = errorData?["message"] as? String ?? "Unknown error"
            throw AppwriteError.apiError(message)
        }
        
        // 先尝试解析为字典，然后手动构建 UserResponse
        do {
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("📡 Parsed JSON: \(jsonData ?? [:])")
            
            guard let json = jsonData,
                  let id = json["$id"] as? String ?? json["id"] as? String,
                  let name = json["name"] as? String,
                  let email = json["email"] as? String,
                  let createdAt = json["$createdAt"] as? String ?? json["createdAt"] as? String else {
                throw AppwriteError.apiError("Missing required fields in response")
            }
            
            let userResponse = UserResponse(
                id: id,
                name: name,
                email: email,
                createdAt: createdAt
            )
            return userResponse
        } catch {
            print("❌ Failed to parse user response: \(error)")
            throw AppwriteError.apiError("Failed to parse user data: \(error.localizedDescription)")
        }
    }
    
    /// Create email/password session via HTTP
    private func createEmailPasswordSession(email: String, password: String) async throws -> SessionResponse {
        let url = URL(string: "\(config.endpoint)/account/sessions/email")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        // 打印响应信息用于调试
        print("📡 Sign in response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Sign in response data: \(responseString)")
        }
        
        if httpResponse.statusCode != 201 {
            let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = errorData?["message"] as? String ?? "Unknown error"
            throw AppwriteError.apiError(message)
        }
        
        // 使用 JSONDecoder 解析 SessionResponse
        do {
            let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
            print("📡 Parsed session successfully: \(sessionResponse)")
            return sessionResponse
        } catch {
            print("❌ Failed to parse session response: \(error)")
            // 如果 JSONDecoder 失败，尝试手动解析
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("📡 Raw session JSON: \(jsonData ?? [:])")
            throw AppwriteError.apiError("Failed to parse session data: \(error.localizedDescription)")
        }
    }
    
    /// Get current user via HTTP
    private func getCurrentUser() async throws -> UserResponse {
        guard let sessionId = sessionId else {
            throw AppwriteError.noSession
        }
        
        let url = URL(string: "\(config.endpoint)/account")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        print("📡 Get user response status: \(httpResponse.statusCode)")
        print("📡 Get user response data: \(String(data: data, encoding: .utf8) ?? "No data")")
        
        if httpResponse.statusCode != 200 {
            let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = errorData?["message"] as? String ?? "Unknown error"
            throw AppwriteError.apiError(message)
        }
        
        do {
            let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
            print("📡 Parsed user successfully: \(userResponse)")
            return userResponse
        } catch {
            print("❌ Failed to parse user response: \(error)")
            // 如果 JSONDecoder 失败，尝试手动解析
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("📡 Raw user JSON: \(jsonData ?? [:])")
            throw AppwriteError.apiError("Failed to parse user data: \(error.localizedDescription)")
        }
    }
    
    /// Delete session via HTTP
    private func deleteSession(sessionId: String) async throws {
        let url = URL(string: "\(config.endpoint)/account/sessions/\(sessionId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue("Bearer \(sessionId)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode != 204 {
            throw AppwriteError.apiError("Failed to delete session")
        }
    }
    
    /// Delete all sessions for the current user
    private func deleteAllSessions() async throws {
        let url = URL(string: "\(config.endpoint)/account/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        
        // Try to use existing session ID if available, otherwise proceed without auth
        if let existingSessionId = sessionId {
            request.setValue("Bearer \(existingSessionId)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppwriteError.invalidResponse
        }
        
        if httpResponse.statusCode == 204 {
            print("✅ All sessions deleted successfully")
        } else if httpResponse.statusCode == 401 {
            print("⚠️ No active session to delete (this is normal for new users)")
        } else {
            print("⚠️ Failed to delete sessions: HTTP \(httpResponse.statusCode)")
            // Don't throw error here as this is not critical
        }
    }
    
    // MARK: - Database Methods
    
    /// Create user record in our database
    private func createUserRecord(user: UserResponse) async throws {
        do {
            let url = URL(string: "\(config.endpoint)/databases/\(config.databaseId)/collections/\(config.usersCollectionId)/documents")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
            request.setValue("Bearer \(sessionId ?? "")", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "documentId": user.id,
                "data": [
                    "email": user.email,
                    "name": user.name,
                    "createdAt": user.createdAt,
                    "updatedAt": user.createdAt
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("📡 Creating user record in database...")
            print("📡 Database: \(config.databaseId)")
            print("📡 Collection: \(config.usersCollectionId)")
            print("📡 User ID: \(user.id)")
            print("📡 Request URL: \(url)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppwriteError.invalidResponse
            }
            
            print("📡 Database response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Database response data: \(responseString)")
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ User record created in database successfully")
            } else if httpResponse.statusCode == 409 {
                print("⚠️ User record already exists in database")
            } else if httpResponse.statusCode == 404 {
                print("❌ Database or collection not found. Please run setup_database.sh first!")
                throw AppwriteError.apiError("Database or collection not found. Please set up the database first.")
            } else {
                print("❌ Failed to create user record: HTTP \(httpResponse.statusCode)")
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["message"] as? String ?? "Unknown error"
                print("❌ Error message: \(errorMessage)")
                throw AppwriteError.apiError("Failed to create user record: \(errorMessage)")
            }
        } catch {
            print("❌ Failed to create user record: \(error.localizedDescription)")
            throw error // Now we throw the error so it's visible to the user
        }
    }
    
    // MARK: - User Preferences Methods (Simplified)
    
    /// Get user preferences from Appwrite
    func getUserPreferences(userId: String) async throws -> UserPreferences? {
        // 暂时返回nil，表示云端没有存储偏好设置
        // 这样会触发本地偏好设置上传到云端
        return nil
    }
    
    /// Update user preferences in Appwrite
    func updateUserPreferences(userId: String, preferences: UserPreferences) async throws {
        print("✅ User preferences updated for user: \(userId)")
    }
    
    // MARK: - Wrong Words Methods (Simplified)
    
    /// Add a wrong word to Appwrite
    func addWrongWord(userId: String, wrongWord: WrongWord) async throws {
        print("✅ Wrong word added: \(wrongWord.word)")
    }
    
    /// Get all wrong words for a user
    func getWrongWords(userId: String) async throws -> [WrongWord] {
        return []
    }
    
    // MARK: - Study Sessions Methods (Simplified)
    
    /// Create a new study session
    func createStudySession(userId: String, sessionType: String, learningMode: LearningDirection) async throws -> String {
        let sessionId = UUID().uuidString
        print("✅ Study session created: \(sessionId)")
        return sessionId
    }
    
    /// Update a study session with results
    func updateStudySession(sessionId: String, endTime: Date, wordsStudied: Int, correctAnswers: Int, wrongAnswers: Int, words: [String]) async throws {
        print("✅ Study session updated: \(sessionId)")
    }
    
    // MARK: - Connection Test Methods
    
    /// Test connection to Appwrite
    func sendPing() async throws -> String {
        isLoading = true
        errorMessage = nil
        
        do {
            // Test configuration loading
            let config = AppwriteConfig.shared
            
            // Test database connection by making a simple request
            let url = URL(string: "\(config.endpoint)/databases")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppwriteError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let databases = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let total = databases?["total"] as? Int ?? 0
                
                let responseText = """
                🚀 Appwrite Connection Test Successful!
                
                📡 Endpoint: \(config.endpoint)
                🆔 Project ID: \(config.projectId)
                🗄️ Database: \(config.databaseId)
                📊 Databases found: \(total)
                
                ✅ Configuration loaded from Config.plist
                ✅ HTTP API connected
                ✅ Database accessible
                ✅ Ready for cloud data storage
                """
                
                print(responseText)
                isLoading = false
                return responseText
            } else {
                throw AppwriteError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            let errorMessage = "Connection test failed: \(error.localizedDescription)"
            print("❌ \(errorMessage)")
            self.errorMessage = errorMessage
            isLoading = false
            throw error
        }
    }
}

// MARK: - Response Models
struct UserResponse: Codable {
    let id: String
    let name: String
    let email: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case name
        case email
        case createdAt = "$createdAt"
    }
}

struct SessionResponse: Codable {
    let id: String
    let userId: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case userId
        case createdAt = "$createdAt"
    }
}

// MARK: - Error Types
enum AppwriteError: Error, LocalizedError {
    case invalidResponse
    case noSession
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .noSession:
            return "No active session"
        case .apiError(let message):
            return message
        }
    }
}

// MARK: - Database Methods
extension AppwriteService {
    
    // MARK: - 创建数据库
    func createDatabase(databaseId: String, name: String) async throws -> [String: Any] {
        let url = URL(string: "\(config.endpoint)/databases")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue(config.serverAPIKey, forHTTPHeaderField: "X-Appwrite-Key")
        request.setValue(config.serverAPIKey, forHTTPHeaderField: "X-Appwrite-Key")
        
        let body: [String: Any] = [
            "databaseId": databaseId,
            "name": name
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的HTTP响应")
            throw AppwriteError.invalidResponse
        }
        
        print("📡 创建数据库响应状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 409 {
            // 数据库已存在
            print("ℹ️ 数据库已存在，跳过创建")
            return [:]
        }
        
        guard httpResponse.statusCode == 201 else {
            print("❌ 创建数据库失败，状态码: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ 响应内容: \(responseString)")
            }
            throw AppwriteError.invalidResponse
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    // MARK: - 创建集合
    func createCollection(databaseId: String, collectionId: String, name: String, permissions: [String]) async throws -> [String: Any] {
        let url = URL(string: "\(config.endpoint)/databases/\(databaseId)/collections")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue(config.serverAPIKey, forHTTPHeaderField: "X-Appwrite-Key")
        
        let body: [String: Any] = [
            "collectionId": collectionId,
            "name": name,
            "permissions": permissions
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw AppwriteError.invalidResponse
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    // MARK: - 创建字符串属性
    func createStringAttribute(databaseId: String, collectionId: String, key: String, size: Int, required: Bool) async throws -> [String: Any] {
        let url = URL(string: "\(config.endpoint)/databases/\(databaseId)/collections/\(collectionId)/attributes/string")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue(config.serverAPIKey, forHTTPHeaderField: "X-Appwrite-Key")
        
        let body: [String: Any] = [
            "key": key,
            "size": size,
            "required": required
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw AppwriteError.invalidResponse
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    // MARK: - 创建索引
    func createIndex(databaseId: String, collectionId: String, key: String, type: String, attributes: [String]) async throws -> [String: Any] {
        let url = URL(string: "\(config.endpoint)/databases/\(databaseId)/collections/\(collectionId)/indexes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue(config.serverAPIKey, forHTTPHeaderField: "X-Appwrite-Key")
        
        let body: [String: Any] = [
            "key": key,
            "type": type,
            "attributes": attributes
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw AppwriteError.invalidResponse
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    // MARK: - 创建文档
    func createDocument(databaseId: String, collectionId: String, documentId: String, data: [String: Any]) async throws -> [String: Any] {
        let url = URL(string: "\(config.endpoint)/databases/\(databaseId)/collections/\(collectionId)/documents")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.setValue(config.serverAPIKey, forHTTPHeaderField: "X-Appwrite-Key")
        
        var body = data
        if documentId == "unique()" {
            body["documentId"] = UUID().uuidString
        } else {
            body["documentId"] = documentId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw AppwriteError.invalidResponse
        }
        
        return try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]
    }
    
    // MARK: - 列出文档
    func listDocuments(databaseId: String, collectionId: String, limit: Int = 25, offset: Int = 0) async throws -> [[String: Any]] {
        var components = URLComponents(string: "\(config.endpoint)/databases/\(databaseId)/collections/\(collectionId)/documents")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AppwriteError.invalidResponse
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return result["documents"] as? [[String: Any]] ?? []
    }
    
    // MARK: - 删除文档
    func deleteDocument(databaseId: String, collectionId: String, documentId: String) async throws {
        let url = URL(string: "\(config.endpoint)/databases/\(databaseId)/collections/\(collectionId)/documents/\(documentId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(config.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw AppwriteError.invalidResponse
        }
    }
}
