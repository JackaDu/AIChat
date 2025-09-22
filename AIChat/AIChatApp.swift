//
//  AIChatApp.swift
//  AIChat
//
//  Created by Hao Du on 8/31/25.
//

import SwiftUI
import SwiftData

@main
struct AIChatApp: App {
    @StateObject private var appwriteService = AppwriteService()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appwriteService)
                .onAppear {
                    // 应用启动时自动运行静默迁移
                    Task {
                        await StartupMigration.shared.runSilentMigration()
                    }
                }
        }
        // 移除SwiftData容器，简化应用
    }
}

// MARK: - 迁移完成通知
extension Notification.Name {
    static let migrationCompleted = Notification.Name("migrationCompleted")
}
