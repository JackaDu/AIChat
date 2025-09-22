# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

AIChat is a SwiftUI-based iOS application for AI-powered English conversation practice. The app uses role-playing scenarios to help users practice English vocabulary and grammar through interactive voice conversations. It integrates with OpenAI's APIs for speech recognition (ASR), text-to-speech (TTS), and chat completion.

**Target Platform:** iOS 18.5+, supports iPhone and iPad  
**Language:** Swift 5.0  
**UI Framework:** SwiftUI with SwiftData for persistence  
**Development Tool:** Xcode 16.4+

## Development Commands

### Building and Running
```bash
# Open the project in Xcode
open AIChat.xcodeproj

# Build from command line (requires Xcode CLI tools)
xcodebuild -project AIChat.xcodeproj -scheme AIChat -configuration Debug build

# Run unit tests
xcodebuild test -project AIChat.xcodeproj -scheme AIChat -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for release
xcodebuild -project AIChat.xcodeproj -scheme AIChat -configuration Release build
```

### Code Analysis and Maintenance
```bash
# SwiftLint (if configured)
swiftlint

# Clean build folder
xcodebuild clean -project AIChat.xcodeproj -scheme AIChat

# Archive for distribution
xcodebuild archive -project AIChat.xcodeproj -scheme AIChat -archivePath build/AIChat.xcarchive
```

### Testing Individual Components
- **Unit Tests:** Run specific test classes in `AIChatTests/`
- **UI Tests:** Run specific UI test cases in `AIChatUITests/`
- **Voice Features:** Test on physical device (speech recognition requires hardware)

## Code Architecture

### App Structure (Tab-Based Navigation)
The app follows a standard SwiftUI tab-based architecture:

1. **`RootTabView`** - Main tab container with two tabs:
   - **Speak Tab:** Scene selection and conversation practice
   - **Cards Tab:** Review vocabulary cards earned through practice

2. **Core Conversation Flow:**
   - `ScenePickerView` → `SpeakQuickView` → `SessionReviewView`
   - Users select a practice scenario, engage in AI conversation, then review performance

### Key Data Models

**`ScenePack`** - Defines practice scenarios with:
- Role-playing setup (user role + AI role)
- Target vocabulary words with Chinese translations
- Grammar focus points
- Visual themes and opening dialogue

**`Card`** (SwiftData model) - Vocabulary cards generated from conversations:
- Word, meaning, example sentence
- Mastery status tracking
- Auto-generated from conversation mistakes/new words

**`ChatMessage`** - Represents individual messages in conversation timeline:
- Sender type (user/AI/system)
- English text with optional Chinese translation
- Used for WeChat-style chat interface

### Service Layer Architecture

**`SpeakService`** - Main backend communication:
- Sends user text + conversation context to custom API endpoint
- Receives structured responses with AI reply, corrections, hints, and generated cards
- Handles both mock data (for testing) and live API integration

**`OpenAIASR`** - Speech recognition service:
- Records audio to local m4a files
- Uploads to OpenAI Whisper API for transcription
- Supports bias terms to improve recognition of target vocabulary

**`OpenAIVoiceService`** - Text-to-speech service:
- Converts text to speech using OpenAI's TTS API
- Fallback to system AVSpeechSynthesizer if API fails
- Supports multiple voices and audio formats

### UI Architecture Patterns

**MVVM with ObservableObject:**
- `ChatViewModel` manages conversation state and backend interactions
- SwiftUI views observe published properties for reactive UI updates

**Compositional View Structure:**
- Heavy use of custom view components (`Avatar`, `ChatTimeline`, `SceneCard`, etc.)
- Views separated by responsibility (data vs presentation)

**Sheet-Based Modal Flow:**
- Scene briefing sheets for onboarding
- Session review sheets for post-conversation analysis
- Progressive disclosure of information

### Session Management & Review System

**Conversation Context:**
- Maintains conversation history for LLM context
- Tracks target word usage and grammar patterns
- Accumulates mistakes and pronunciation issues throughout session

**Performance Analysis:**
- `ReviewEngine` calculates scores based on vocabulary coverage, grammar accuracy, pronunciation
- `PronunciationAnalyzer` uses Speech framework for detailed phonetic feedback
- `SessionReview` provides structured feedback with specific improvement recommendations

## API Integration

### Required Configuration
The app requires an OpenAI API key in `Info.plist`:
```xml
<key>OpenAIAPIKey</key>
<string>your-api-key-here</string>
```

### Custom Backend API
The app expects a custom backend at the endpoint defined in `SpeakService`:
- **Current endpoint:** `https://84b9c8f6f803.ngrok-free.app/api/speak`
- **Expected request format:** `SpeakRequest` with user text, target words, grammar focus, conversation history
- **Expected response format:** `SpeakResponse` with AI reply, corrections, hints, vocabulary cards

### OpenAI Services Integration
- **Speech-to-Text:** Uses OpenAI Whisper API via multipart form upload
- **Text-to-Speech:** Uses OpenAI TTS API for high-quality voice synthesis
- **Conversation:** Relies on custom backend (presumably using OpenAI's chat APIs internally)

## Key Development Considerations

### Audio & Permissions
- Requires microphone and speech recognition permissions
- Audio session management is critical for proper recording/playback
- Test audio features on physical devices, not simulator

### SwiftData Persistence
- Cards are automatically generated and persisted using SwiftData
- Model container configured in `AIChatApp.swift`
- Consider migration strategies when modifying the `Card` model

### Localization Support
- App supports bilingual content (English practice with Chinese assistance)
- Chinese translations provided for all AI responses and system messages
- Consider expanding localization for broader market support

### Performance Considerations
- Audio files temporarily stored in `NSTemporaryDirectory`
- Conversation history limited to recent 6 messages to manage API costs
- UI uses lazy loading for chat timeline to handle long conversations

### Error Handling Strategy
- Graceful fallbacks for API failures (local TTS when OpenAI TTS fails)
- User-friendly error messages in chat interface
- Comprehensive error handling in network layer with detailed logging
