# AIChat App Store 发布指南

## 📱 应用信息概览

- **应用名称**: AIChat
- **Bundle ID**: jack.AIChat
- **当前版本**: 1.0 (Build 1)
- **最低支持版本**: iOS 18.5+
- **开发语言**: SwiftUI

## ⚠️ 发布前必须完成的准备工作

### 1. 移除敏感信息
**🚨 重要：必须立即处理**

当前 `Info.plist` 中包含了OpenAI API密钥，这是严重的安全问题：

```xml
<key>OpenAIAPIKey</key>
<string>YOUR_OPENAI_API_KEY_HERE</string>
```

**解决方案**：
1. 将API密钥移到服务器端
2. 使用环境变量或安全的配置管理
3. 从Info.plist中完全移除

### 2. 更新Bundle Identifier
当前Bundle ID `jack.AIChat` 可能不符合App Store要求。

**建议的Bundle ID格式**：
- `com.yourcompany.aichat`
- `com.yourname.aichat`
- `com.yourdomain.aichat`

### 3. 完善应用信息

#### 应用图标
- 需要提供完整的图标集（从20x20到1024x1024）
- 当前只有基本的AppIcon配置

#### 应用描述
需要准备以下内容：
- 应用名称（App Store显示）
- 副标题（简短描述）
- 关键词（搜索优化）
- 详细描述
- 更新说明
- 隐私政策URL
- 支持URL

## 🛠️ 技术准备步骤

### 1. 修复安全问题
```bash
# 1. 备份当前Info.plist
cp AIChat/Info.plist AIChat/Info.plist.backup

# 2. 创建新的Info.plist（移除API密钥）
# 3. 实现安全的API密钥管理
```

### 2. 更新项目配置
在Xcode中：
1. 选择项目 → AIChat target
2. 更新Bundle Identifier
3. 设置正确的Team和Signing
4. 配置App Store Connect

### 3. 准备发布版本
```bash
# 1. 更新版本号
# 在Xcode中：General → Version: 1.0, Build: 1

# 2. 选择Release配置
# Product → Scheme → Edit Scheme → Archive → Build Configuration: Release

# 3. 清理项目
# Product → Clean Build Folder
```

## 📋 App Store Connect 配置

### 1. 创建应用记录
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 点击"我的App" → "+" → "新建App"
3. 填写应用信息：
   - 平台：iOS
   - 名称：AIChat
   - 主要语言：中文（简体）
   - Bundle ID：选择或创建对应的Bundle ID
   - SKU：唯一标识符

### 2. 应用信息配置
```
应用名称: AIChat - 智能英语学习助手
副标题: AI驱动的个性化英语词汇学习应用

关键词: 英语学习,词汇,AI,智能学习,错题本,记忆曲线

描述:
AIChat是一款基于AI技术的智能英语学习应用，专为英语学习者设计。

主要功能：
• 智能词汇学习：基于艾宾浩斯遗忘曲线的科学复习计划
• 个性化错题本：自动记录学习难点，针对性复习
• 多种学习模式：认识单词、回忆单词，全面提升词汇能力
• 智能选项生成：AI生成干扰选项，提高学习效果
• 发音功能：标准美式发音，帮助正确掌握单词读音
• 学习统计：详细的学习数据分析和进度跟踪

适合人群：
• 中学生、大学生
• 英语考试备考者
• 英语爱好者
• 需要提升词汇量的学习者

让AI成为你的英语学习伙伴，让学习更高效、更有趣！
```

### 3. 隐私信息
需要提供：
- 隐私政策URL
- 数据收集说明
- 第三方服务使用说明

## 🚀 发布流程

### 1. 构建Archive
```bash
# 在Xcode中
# Product → Archive
# 等待构建完成
```

### 2. 上传到App Store Connect
1. 在Organizer中选择Archive
2. 点击"Distribute App"
3. 选择"App Store Connect"
4. 选择"Upload"
5. 等待上传完成

### 3. 提交审核
1. 在App Store Connect中
2. 选择构建版本
3. 填写审核信息
4. 提交审核

## ⏱️ 时间线预估

- **准备阶段**: 2-3天
  - 修复安全问题
  - 完善应用信息
  - 准备素材

- **审核阶段**: 1-7天
  - 苹果审核时间
  - 可能需要修改和重新提交

- **发布**: 审核通过后立即发布

## 🔧 当前需要立即处理的问题

### 高优先级
1. **🚨 移除API密钥** - 安全风险
2. **更新Bundle ID** - 发布要求
3. **完善应用图标** - 用户体验

### 中优先级
1. **编写应用描述** - 营销效果
2. **准备隐私政策** - 法律要求
3. **测试所有功能** - 质量保证

### 低优先级
1. **优化应用性能** - 用户体验
2. **添加更多功能** - 竞争优势

## 📞 需要帮助？

如果在发布过程中遇到问题，可以：
1. 查看苹果官方文档
2. 联系苹果开发者支持
3. 参考其他成功案例

---

**注意**: 发布到App Store是一个严肃的过程，请确保应用质量高、功能完整、符合苹果审核指南。建议先在TestFlight进行内测，确保应用稳定后再提交审核。
