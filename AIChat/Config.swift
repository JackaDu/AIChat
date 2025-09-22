import Foundation

// MARK: - 应用配置管理
class AppConfig {
    static let shared = AppConfig()
    
    private init() {}
    
    // MARK: - API配置
    var openAIAPIKey: String {
        // 从环境变量或安全的配置文件读取
        // 生产环境中应该从服务器获取或使用更安全的方式
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    // MARK: - 应用信息
    var appName: String {
        return "AIChat"
    }
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - 功能开关
    var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var enableAnalytics: Bool {
        return !isDebugMode
    }
    
    // MARK: - 服务器配置
    var baseURL: String {
        if isDebugMode {
            return "https://api-dev.yourapp.com"
        } else {
            return "https://api.yourapp.com"
        }
    }
}

// MARK: - 环境变量配置示例
/*
 在Xcode中设置环境变量：
 1. 选择Scheme → Edit Scheme
 2. Run → Arguments → Environment Variables
 3. 添加: OPENAI_API_KEY = your_actual_api_key_here
 
 或者创建Config.plist文件（不要提交到Git）：
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
     <key>OpenAIAPIKey</key>
     <string>your_actual_api_key_here</string>
 </dict>
 </plist>
 */