# Appwrite Database Setup Guide

## 🚀 Quick Setup Steps

### 1. Go to Appwrite Console
- Visit: https://cloud.appwrite.io
- Sign in to your account
- Select your project: `english_words` (ID: 68c91bbf0031de5f210b)

### 2. Create Database
- Go to **Databases** section
- Click **Create Database**
- Name: `english_learning`
- Database ID: `english_learning`

### 3. Create Collections

#### Collection 1: Users
- **Collection ID**: `users`
- **Name**: Users
- **Permissions**: 
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- id (String, 255, required, array: false)
- email (String, 255, required, array: false)
- name (String, 255, required, array: false)
- createdAt (DateTime, required, array: false)
- updatedAt (DateTime, required, array: false)
```

#### Collection 2: User Preferences
- **Collection ID**: `user_preferences`
- **Name**: User Preferences
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- selectedGrade (String, 50, required, array: false)
- selectedVocabularyType (String, 50, required, array: false)
- dailyStudyAmount (String, 50, required, array: false)
- hasSelectedStudyAmount (Boolean, required, array: false)
- isFirstLaunch (Boolean, required, array: false)
- createdAt (DateTime, required, array: false)
- updatedAt (DateTime, required, array: false)
```

#### Collection 3: Wrong Words
- **Collection ID**: `wrong_words`
- **Name**: Wrong Words
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- word (String, 255, required, array: false)
- meaning (String, 500, required, array: false)
- context (String, 1000, required, array: false)
- learningDirection (String, 50, required, array: false)
- mistakeCount (Integer, required, array: false)
- lastReviewedAt (DateTime, required, array: false)
- createdAt (DateTime, required, array: false)
- updatedAt (DateTime, required, array: false)
```

#### Collection 4: Study Sessions
- **Collection ID**: `study_sessions`
- **Name**: Study Sessions
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- sessionType (String, 50, required, array: false)
- totalWords (Integer, required, array: false)
- correctAnswers (Integer, required, array: false)
- wrongAnswers (Integer, required, array: false)
- duration (Integer, required, array: false)
- completedAt (DateTime, required, array: false)
- createdAt (DateTime, required, array: false)
```

#### Collection 5: Study Words
- **Collection ID**: `study_words`
- **Name**: Study Words
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- word (String, 255, required, array: false)
- meaning (String, 500, required, array: false)
- phonetic (String, 100, required, array: false)
- partOfSpeech (String, 50, required, array: false)
- example (String, 1000, required, array: false)
- memoryStrength (Float, required, array: false)
- lastReviewedAt (DateTime, required, array: false)
- nextReviewAt (DateTime, required, array: false)
- createdAt (DateTime, required, array: false)
- updatedAt (DateTime, required, array: false)
```

#### Collection 6: Learning Progress
- **Collection ID**: `learning_progress`
- **Name**: Learning Progress
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- date (String, 10, required, array: false) // YYYY-MM-DD format
- wordsStudied (Integer, required, array: false)
- wordsCorrect (Integer, required, array: false)
- wordsWrong (Integer, required, array: false)
- studyTime (Integer, required, array: false) // in minutes
- streak (Integer, required, array: false)
- createdAt (DateTime, required, array: false)
- updatedAt (DateTime, required, array: false)
```

#### Collection 7: Word Attempts
- **Collection ID**: `word_attempts`
- **Name**: Word Attempts
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- word (String, 255, required, array: false)
- learningDirection (String, 50, required, array: false)
- isCorrect (Boolean, required, array: false)
- responseTime (Integer, required, array: false) // in milliseconds
- sessionId (String, 255, required, array: false)
- createdAt (DateTime, required, array: false)
```

#### Collection 8: User Achievements
- **Collection ID**: `user_achievements`
- **Name**: User Achievements
- **Permissions**:
  - Create: `users`
  - Read: `users`
  - Update: `users`
  - Delete: `users`

**Attributes:**
```
- userId (String, 255, required, array: false)
- achievementType (String, 50, required, array: false)
- achievementName (String, 255, required, array: false)
- description (String, 500, required, array: false)
- unlockedAt (DateTime, required, array: false)
- createdAt (DateTime, required, array: false)
```

### 4. Set Up Indexes

For better performance, create these indexes:

#### Users Collection:
- `email` (unique)

#### User Preferences Collection:
- `userId` (unique)

#### Wrong Words Collection:
- `userId`
- `word`
- `userId, word` (composite)

#### Study Sessions Collection:
- `userId`
- `completedAt`

#### Study Words Collection:
- `userId`
- `word`
- `nextReviewAt`
- `userId, nextReviewAt` (composite)

#### Learning Progress Collection:
- `userId`
- `date`
- `userId, date` (composite)

#### Word Attempts Collection:
- `userId`
- `word`
- `sessionId`
- `createdAt`

#### User Achievements Collection:
- `userId`
- `achievementType`
- `userId, achievementType` (composite)

### 5. Set Up Authentication

1. Go to **Authentication** section
2. Enable **Email/Password** provider
3. Configure email templates if needed

### 6. Test the Setup

After creating all collections, you can test by running the app and checking if the authentication and data operations work correctly.

## 🔧 Alternative: Use Appwrite CLI

If you prefer command line, you can also use the Appwrite CLI to create these collections programmatically.
