# AIChat Database Design v2.0

## 概述
重新设计所有 Appwrite 数据库表结构，使用英文表名，移除重复的时间戳字段。

## 表结构设计

### 1. users (用户表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `email` (String, 255, Required) - 用户邮箱
- `name` (String, 255, Required) - 用户姓名
- `nickname` (String, 100, Optional) - 用户昵称
- `avatar` (String, 50, Optional) - 头像图标
- `avatarColor` (String, 20, Optional) - 头像颜色
- `isActive` (Boolean, Required, Default: true) - 是否激活
- `lastLoginAt` (DateTime, Optional) - 最后登录时间

### 2. user_preferences (用户偏好设置表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `selectedGrade` (String, 20, Required) - 选择的年级
- `selectedCourseType` (String, 20, Required) - 课程类型
- `selectedRequiredCourse` (String, 50, Optional) - 必修课程
- `selectedElectiveCourse` (String, 50, Optional) - 选修课程
- `selectedUnits` (String Array, Optional) - 选择的单元
- `dailyStudyAmount` (String, 20, Required) - 每日学习量
- `isFirstLaunch` (Boolean, Required, Default: true) - 是否首次启动
- `userNickname` (String, 100, Optional) - 用户昵称
- `userAvatar` (String, 50, Optional) - 用户头像
- `userAvatarColor` (String, 20, Optional) - 头像颜色

### 3. wrong_words (错题记录表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `word` (String, 255, Required) - 单词
- `meaning` (String, 500, Required) - 中文意思
- `context` (String, 1000, Optional) - 上下文/例句
- `learningDirection` (String, 50, Required) - 学习方向
- `reviewDates` (DateTime Array, Optional) - 复习日期数组
- `nextReviewDate` (DateTime, Required) - 下次复习日期
- `reviewCount` (Integer, Required, Default: 0) - 复习次数
- `isMastered` (Boolean, Required, Default: false) - 是否已掌握
- `errorCount` (Integer, Required, Default: 1) - 错误次数
- `totalAttempts` (Integer, Required, Default: 1) - 总尝试次数
- `textbookSource` (String, 100, Optional) - 教材来源
- `partOfSpeech` (String, 50, Optional) - 词性
- `examSource` (String, 100, Optional) - 考试来源
- `difficulty` (String, 20, Required, Default: "medium") - 难度等级
- `lastReviewDate` (DateTime, Optional) - 最近复习日期
- `consecutiveCorrect` (Integer, Required, Default: 0) - 连续答对次数
- `consecutiveWrong` (Integer, Required, Default: 1) - 连续答错次数
- `deviceId` (String, 255, Optional) - 设备ID
- `syncStatus` (String, 20, Required, Default: "pending") - 同步状态

### 4. study_sessions (学习会话表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `sessionType` (String, 50, Required) - 会话类型
- `totalWords` (Integer, Required) - 总单词数
- `correctWords` (Integer, Required) - 正确单词数
- `wrongWords` (Integer, Required) - 错误单词数
- `duration` (Integer, Required) - 持续时间(秒)
- `isCompleted` (Boolean, Required, Default: false) - 是否完成
- `startTime` (DateTime, Required) - 开始时间
- `endTime` (DateTime, Optional) - 结束时间
- `deviceId` (String, 255, Optional) - 设备ID

### 5. study_words (学习单词表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `sessionId` (String, 255, Required) - 学习会话ID
- `word` (String, 255, Required) - 单词
- `meaning` (String, 500, Required) - 中文意思
- `learningDirection` (String, 50, Required) - 学习方向
- `isCorrect` (Boolean, Required) - 是否正确
- `responseTime` (Integer, Optional) - 响应时间(毫秒)
- `attemptCount` (Integer, Required, Default: 1) - 尝试次数
- `textbookSource` (String, 100, Optional) - 教材来源
- `partOfSpeech` (String, 50, Optional) - 词性

### 6. learning_progress (学习进度表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `word` (String, 255, Required) - 单词
- `meaning` (String, 500, Required) - 中文意思
- `learningDirection` (String, 50, Required) - 学习方向
- `masteryLevel` (Integer, Required, Default: 0) - 掌握程度 (0-5)
- `totalAttempts` (Integer, Required, Default: 0) - 总尝试次数
- `correctAttempts` (Integer, Required, Default: 0) - 正确次数
- `lastStudiedAt` (DateTime, Optional) - 最后学习时间
- `nextReviewAt` (DateTime, Required) - 下次复习时间
- `isMastered` (Boolean, Required, Default: false) - 是否已掌握
- `textbookSource` (String, 100, Optional) - 教材来源
- `partOfSpeech` (String, 50, Optional) - 词性

### 7. word_attempts (单词尝试记录表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `word` (String, 255, Required) - 单词
- `learningDirection` (String, 50, Required) - 学习方向
- `isCorrect` (Boolean, Required) - 是否正确
- `responseTime` (Integer, Optional) - 响应时间(毫秒)
- `selectedAnswer` (String, 500, Optional) - 选择的答案
- `correctAnswer` (String, 500, Required) - 正确答案
- `sessionId` (String, 255, Optional) - 学习会话ID
- `deviceId` (String, 255, Optional) - 设备ID

### 8. user_achievements (用户成就表)
- `$id` (String) - Appwrite 自动生成
- `$createdAt` (DateTime) - Appwrite 自动生成
- `$updatedAt` (DateTime) - Appwrite 自动生成
- `userId` (String, 255, Required) - 用户ID
- `achievementType` (String, 50, Required) - 成就类型
- `achievementName` (String, 100, Required) - 成就名称
- `achievementDescription` (String, 500, Required) - 成就描述
- `isUnlocked` (Boolean, Required, Default: false) - 是否解锁
- `unlockedAt` (DateTime, Optional) - 解锁时间
- `progress` (Integer, Required, Default: 0) - 进度
- `maxProgress` (Integer, Required) - 最大进度
- `icon` (String, 50, Optional) - 图标
- `color` (String, 20, Optional) - 颜色

## 权限设置
所有表都使用以下权限：
- `read("users")` - 用户可读
- `create("users")` - 用户可创建
- `update("users")` - 用户可更新
- `delete("users")` - 用户可删除

## 索引建议
- `userId` 字段需要索引以提高查询性能
- `word` 字段需要索引以支持单词搜索
- `learningDirection` 字段需要索引以支持学习方向筛选
- `nextReviewDate` 字段需要索引以支持复习提醒
