# Appwrite Database Schema Design for English Learning App

## Overview
This document outlines the database schema design for storing user-related data in your English learning app using Appwrite. The schema is designed to support user preferences, learning progress, wrong words, study sessions, and analytics.

## Database Structure

### 1. Users Collection
**Collection ID**: `users`
**Description**: Stores basic user information and authentication data

```json
{
  "userId": "string (unique)",
  "email": "string",
  "name": "string",
  "avatar": "string (URL)",
  "createdAt": "datetime",
  "lastLoginAt": "datetime",
  "isActive": "boolean",
  "preferences": {
    "selectedGrade": "string",
    "selectedVocabularyType": "string",
    "selectedTextbookVersion": "string",
    "selectedCourseType": "string",
    "selectedRequiredCourse": "string",
    "selectedElectiveCourse": "string",
    "selectedUnits": "array",
    "dailyStudyAmount": "integer",
    "defaultLearningMode": "string"
  }
}
```

**Attributes**:
- `userId`: String, required, unique
- `email`: String, required, unique
- `name`: String, required
- `avatar`: String, optional
- `createdAt`: DateTime, required
- `lastLoginAt`: DateTime, optional
- `isActive`: Boolean, required, default: true
- `preferences`: Object, required

**Indexes**:
- `email` (unique)
- `createdAt`
- `isActive`

---

### 2. User Preferences Collection
**Collection ID**: `user_preferences`
**Description**: Detailed user learning preferences and settings

```json
{
  "userId": "string",
  "grade": "string",
  "vocabularyType": "string",
  "textbookVersion": "string",
  "courseType": "string",
  "requiredCourse": "string",
  "electiveCourse": "string",
  "selectedUnits": "array",
  "dailyStudyAmount": "integer",
  "defaultLearningMode": "string",
  "isFirstLaunch": "boolean",
  "hasSelectedStudyAmount": "boolean",
  "updatedAt": "datetime"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `grade`: String, required (high1, high2, high3)
- `vocabularyType`: String, required (daily, academic, travel, etc.)
- `textbookVersion`: String, required (renjiao, beishida, waiyan)
- `courseType`: String, required (required, elective)
- `requiredCourse`: String, optional (book1, book2, book3)
- `electiveCourse`: String, optional (book1, book2, book3, book4)
- `selectedUnits`: Array, required
- `dailyStudyAmount`: Integer, required (5, 10, 15, 20)
- `defaultLearningMode`: String, required (recognizeMeaning, recallWord)
- `isFirstLaunch`: Boolean, required, default: true
- `hasSelectedStudyAmount`: Boolean, required, default: false
- `updatedAt`: DateTime, required

**Indexes**:
- `userId` (unique)
- `grade`
- `textbookVersion`

---

### 3. Wrong Words Collection
**Collection ID**: `wrong_words`
**Description**: Stores words that users got wrong during learning

```json
{
  "userId": "string",
  "word": "string",
  "meaning": "string",
  "context": "string",
  "learningDirection": "string",
  "dateAdded": "datetime",
  "reviewDates": "array",
  "nextReviewDate": "datetime",
  "reviewCount": "integer",
  "isMastered": "boolean",
  "errorCount": "integer",
  "totalAttempts": "integer",
  "textbookSource": {
    "textbookVersion": "string",
    "courseBook": "string",
    "unit": "string"
  },
  "partOfSpeech": "string",
  "examSource": "string",
  "difficulty": "string",
  "lastReviewDate": "datetime",
  "consecutiveCorrect": "integer",
  "consecutiveWrong": "integer",
  "errorRate": "float"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `word`: String, required
- `meaning`: String, required
- `context`: String, optional
- `learningDirection`: String, required (recognizeMeaning, recallWord)
- `dateAdded`: DateTime, required
- `reviewDates`: Array, required
- `nextReviewDate`: DateTime, required
- `reviewCount`: Integer, required, default: 0
- `isMastered`: Boolean, required, default: false
- `errorCount`: Integer, required, default: 1
- `totalAttempts`: Integer, required, default: 1
- `textbookSource`: Object, optional
- `partOfSpeech`: String, optional
- `examSource`: String, optional
- `difficulty`: String, required (easy, medium, hard)
- `lastReviewDate`: DateTime, optional
- `consecutiveCorrect`: Integer, required, default: 0
- `consecutiveWrong`: Integer, required, default: 1
- `errorRate`: Float, required, default: 1.0

**Indexes**:
- `userId`
- `word`
- `dateAdded`
- `nextReviewDate`
- `isMastered`
- `difficulty`

---

### 4. Study Sessions Collection
**Collection ID**: `study_sessions`
**Description**: Records individual study sessions and their results

```json
{
  "userId": "string",
  "sessionId": "string",
  "sessionType": "string",
  "learningMode": "string",
  "startTime": "datetime",
  "endTime": "datetime",
  "duration": "integer",
  "wordsStudied": "integer",
  "correctAnswers": "integer",
  "wrongAnswers": "integer",
  "accuracy": "float",
  "words": "array",
  "completed": "boolean",
  "interrupted": "boolean"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `sessionId`: String, required, unique
- `sessionType`: String, required (smart_learning, wrong_word_review, urgent_review)
- `learningMode`: String, required (recognizeMeaning, recallWord)
- `startTime`: DateTime, required
- `endTime`: DateTime, optional
- `duration`: Integer, required (seconds)
- `wordsStudied`: Integer, required
- `correctAnswers`: Integer, required, default: 0
- `wrongAnswers`: Integer, required, default: 0
- `accuracy`: Float, required
- `words`: Array, required (list of word IDs studied)
- `completed`: Boolean, required, default: false
- `interrupted`: Boolean, required, default: false

**Indexes**:
- `userId`
- `sessionId` (unique)
- `startTime`
- `sessionType`
- `completed`

---

### 5. Study Words Collection
**Collection ID**: `study_words`
**Description**: Words that users are currently studying or have studied

```json
{
  "userId": "string",
  "word": "string",
  "meaning": "string",
  "example": "string",
  "difficulty": "string",
  "category": "string",
  "grade": "string",
  "source": "string",
  "isCorrect": "boolean",
  "answerTime": "float",
  "preGeneratedOptions": "array",
  "firstStudiedAt": "datetime",
  "lastStudiedAt": "datetime",
  "studyCount": "integer",
  "masteryLevel": "integer"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `word`: String, required
- `meaning`: String, required
- `example`: String, optional
- `difficulty`: String, required
- `category`: String, required
- `grade`: String, required
- `source`: String, required (imported, wrong_word, ai_generated)
- `isCorrect`: Boolean, optional
- `answerTime`: Float, optional (seconds)
- `preGeneratedOptions`: Array, optional
- `firstStudiedAt`: DateTime, required
- `lastStudiedAt`: DateTime, optional
- `studyCount`: Integer, required, default: 0
- `masteryLevel`: Integer, required, default: 0 (0-5 scale)

**Indexes**:
- `userId`
- `word`
- `source`
- `masteryLevel`
- `lastStudiedAt`

---

### 6. Learning Progress Collection
**Collection ID**: `learning_progress`
**Description**: Tracks overall learning progress and statistics

```json
{
  "userId": "string",
  "date": "date",
  "wordsStudied": "integer",
  "correctAnswers": "integer",
  "wrongAnswers": "integer",
  "accuracy": "float",
  "studyTime": "integer",
  "sessionsCompleted": "integer",
  "newWordsLearned": "integer",
  "wordsMastered": "integer",
  "streakDays": "integer",
  "totalWords": "integer",
  "masteryRate": "float"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `date`: Date, required
- `wordsStudied`: Integer, required, default: 0
- `correctAnswers`: Integer, required, default: 0
- `wrongAnswers`: Integer, required, default: 0
- `accuracy`: Float, required, default: 0.0
- `studyTime`: Integer, required, default: 0 (minutes)
- `sessionsCompleted`: Integer, required, default: 0
- `newWordsLearned`: Integer, required, default: 0
- `wordsMastered`: Integer, required, default: 0
- `streakDays`: Integer, required, default: 0
- `totalWords`: Integer, required, default: 0
- `masteryRate`: Float, required, default: 0.0

**Indexes**:
- `userId`
- `date`
- `userId` + `date` (composite)

---

### 7. Word Attempts Collection
**Collection ID**: `word_attempts`
**Description**: Records individual attempts for each word during study sessions

```json
{
  "userId": "string",
  "word": "string",
  "sessionId": "string",
  "attemptNumber": "integer",
  "learningDirection": "string",
  "selectedAnswer": "string",
  "correctAnswer": "string",
  "isCorrect": "boolean",
  "responseTime": "float",
  "timestamp": "datetime",
  "options": "array",
  "difficulty": "string"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `word`: String, required
- `sessionId`: String, required, foreign key to study_sessions
- `attemptNumber`: Integer, required
- `learningDirection`: String, required
- `selectedAnswer`: String, required
- `correctAnswer`: String, required
- `isCorrect`: Boolean, required
- `responseTime`: Float, required (seconds)
- `timestamp`: DateTime, required
- `options`: Array, required (available options)
- `difficulty`: String, required

**Indexes**:
- `userId`
- `word`
- `sessionId`
- `timestamp`
- `isCorrect`

---

### 8. User Achievements Collection
**Collection ID**: `user_achievements`
**Description**: Tracks user achievements and milestones

```json
{
  "userId": "string",
  "achievementId": "string",
  "achievementType": "string",
  "title": "string",
  "description": "string",
  "icon": "string",
  "unlockedAt": "datetime",
  "progress": "integer",
  "maxProgress": "integer",
  "isUnlocked": "boolean",
  "rarity": "string"
}
```

**Attributes**:
- `userId`: String, required, foreign key to users
- `achievementId`: String, required, unique
- `achievementType`: String, required (streak, accuracy, words_learned, etc.)
- `title`: String, required
- `description`: String, required
- `icon`: String, required
- `unlockedAt`: DateTime, optional
- `progress`: Integer, required, default: 0
- `maxProgress`: Integer, required
- `isUnlocked`: Boolean, required, default: false
- `rarity`: String, required (common, rare, epic, legendary)

**Indexes**:
- `userId`
- `achievementId` (unique)
- `achievementType`
- `isUnlocked`

---

## Database Permissions

### Collection Permissions
All collections should have the following permission structure:

**Read Permissions**:
- `users`: `user:${userId}` (users can only read their own data)
- `user_preferences`: `user:${userId}`
- `wrong_words`: `user:${userId}`
- `study_sessions`: `user:${userId}`
- `study_words`: `user:${userId}`
- `learning_progress`: `user:${userId}`
- `word_attempts`: `user:${userId}`
- `user_achievements`: `user:${userId}`

**Write Permissions**:
- All collections: `user:${userId}` (users can only write their own data)

**Delete Permissions**:
- All collections: `user:${userId}` (users can only delete their own data)

---

## Data Relationships

```
Users (1) ←→ (1) User Preferences
Users (1) ←→ (∞) Wrong Words
Users (1) ←→ (∞) Study Sessions
Users (1) ←→ (∞) Study Words
Users (1) ←→ (∞) Learning Progress
Users (1) ←→ (∞) Word Attempts
Users (1) ←→ (∞) User Achievements

Study Sessions (1) ←→ (∞) Word Attempts
```

---

## Appwrite Configuration

### 1. Database Setup
```bash
# Create database
appwrite databases create --databaseId='english_learning' --name='English Learning Database'

# Create collections
appwrite databases createCollection --databaseId='english_learning' --collectionId='users' --name='Users'
appwrite databases createCollection --databaseId='english_learning' --collectionId='user_preferences' --name='User Preferences'
appwrite databases createCollection --databaseId='english_learning' --collectionId='wrong_words' --name='Wrong Words'
appwrite databases createCollection --databaseId='english_learning' --collectionId='study_sessions' --name='Study Sessions'
appwrite databases createCollection --databaseId='english_learning' --collectionId='study_words' --name='Study Words'
appwrite databases createCollection --databaseId='english_learning' --collectionId='learning_progress' --name='Learning Progress'
appwrite databases createCollection --databaseId='english_learning' --collectionId='word_attempts' --name='Word Attempts'
appwrite databases createCollection --databaseId='english_learning' --collectionId='user_achievements' --name='User Achievements'
```

### 2. Attributes Setup
For each collection, you'll need to create the attributes using the Appwrite CLI or console. Here's an example for the users collection:

```bash
# Users collection attributes
appwrite databases createStringAttribute --databaseId='english_learning' --collectionId='users' --key='userId' --size=255 --required=true
appwrite databases createStringAttribute --databaseId='english_learning' --collectionId='users' --key='email' --size=255 --required=true
appwrite databases createStringAttribute --databaseId='english_learning' --collectionId='users' --key='name' --size=255 --required=true
appwrite databases createStringAttribute --databaseId='english_learning' --collectionId='users' --key='avatar' --size=500 --required=false
appwrite databases createDatetimeAttribute --databaseId='english_learning' --collectionId='users' --key='createdAt' --required=true
appwrite databases createDatetimeAttribute --databaseId='english_learning' --collectionId='users' --key='lastLoginAt' --required=false
appwrite databases createBooleanAttribute --databaseId='english_learning' --collectionId='users' --key='isActive' --required=true --default=true
appwrite databases createStringAttribute --databaseId='english_learning' --collectionId='users' --key='preferences' --size=2000 --required=true
```

### 3. Indexes Setup
```bash
# Create indexes for better query performance
appwrite databases createIndex --databaseId='english_learning' --collectionId='users' --key='email_unique' --type='unique' --attributes='["email"]'
appwrite databases createIndex --databaseId='english_learning' --collectionId='wrong_words' --key='user_word' --type='key' --attributes='["userId", "word"]'
appwrite databases createIndex --databaseId='english_learning' --collectionId='study_sessions' --key='user_date' --type='key' --attributes='["userId", "startTime"]'
```

---

## Migration Strategy

### Phase 1: Basic User Data
1. Set up Users and User Preferences collections
2. Migrate existing UserDefaults data to Appwrite
3. Update app to use Appwrite for user preferences

### Phase 2: Learning Data
1. Set up Wrong Words and Study Words collections
2. Migrate existing wrong words data
3. Update learning flows to use Appwrite

### Phase 3: Analytics and Progress
1. Set up remaining collections
2. Implement data synchronization
3. Add offline support with local caching

### Phase 4: Advanced Features
1. Implement achievements system
2. Add advanced analytics
3. Optimize performance and queries

---

## Security Considerations

1. **Data Privacy**: All user data is isolated by userId
2. **Input Validation**: Validate all data before storing
3. **Rate Limiting**: Implement rate limiting for API calls
4. **Data Encryption**: Appwrite handles encryption at rest
5. **Access Control**: Use proper permissions for each collection

---

## Performance Optimization

1. **Indexing**: Create appropriate indexes for common queries
2. **Pagination**: Use pagination for large datasets
3. **Caching**: Implement local caching for frequently accessed data
4. **Batch Operations**: Use batch operations for bulk data updates
5. **Query Optimization**: Optimize queries to reduce data transfer

This schema provides a comprehensive foundation for storing all user-related data in your English learning app while maintaining good performance and security practices.
