# Appwrite API密钥设置指南

## 问题说明
当前脚本无法直接创建数据库，因为需要服务器API密钥权限。

## 🔑 获取API密钥步骤

### 1. 登录Appwrite Console
访问 [https://cloud.appwrite.io](https://cloud.appwrite.io) 并登录

### 2. 选择项目
选择项目ID为 `68c91bbf0031de5f210b` 的项目

### 3. 获取API密钥
1. 在左侧菜单中找到 **"Settings"** 或 **"设置"**
2. 点击 **"API Keys"** 或 **"API密钥"**
3. 点击 **"Create API Key"** 或 **"创建API密钥"**
4. 设置以下权限：
   - ✅ `databases.read`
   - ✅ `databases.write`
   - ✅ `collections.read`
   - ✅ `collections.write`
   - ✅ `documents.read`
   - ✅ `documents.write`
5. 点击 **"Create"** 或 **"创建"**
6. **重要**: 复制生成的API密钥（只显示一次）

### 4. 配置脚本
将获取到的API密钥替换到以下文件中：

#### 方法1: 修改Python脚本
编辑 `simple_migrate.py` 第24行：
```python
"X-Appwrite-Key": "your-actual-api-key-here"
```

#### 方法2: 设置环境变量
```bash
export APPWRITE_API_KEY="your-actual-api-key-here"
```

## 🚀 运行迁移

配置API密钥后，运行：
```bash
python3 simple_migrate.py
```

## 🔒 安全注意事项

1. **不要提交API密钥到代码仓库**
2. **API密钥具有管理员权限，请妥善保管**
3. **可以在Appwrite Console中随时撤销API密钥**

## 📋 权限说明

需要的权限：
- `databases.write` - 创建数据库
- `collections.write` - 创建集合
- `documents.write` - 上传文档

## 🛠️ 替代方案

如果无法获取API密钥，可以考虑：

1. **手动创建数据库结构**
   - 在Appwrite Console中手动创建数据库
   - 手动创建集合和属性
   - 使用客户端权限上传数据

2. **使用Appwrite SDK**
   - 在应用中集成Appwrite SDK
   - 使用用户认证进行数据操作

## 📞 支持

如果遇到问题：
1. 检查API密钥是否正确
2. 确认权限设置是否完整
3. 验证网络连接是否正常
4. 查看Appwrite Console的错误日志





