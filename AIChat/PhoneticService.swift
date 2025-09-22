import Foundation
import AVFoundation

// MARK: - 音标服务
class PhoneticService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var isStopped = false
    
    // 获取音标
    func getPhoneticSymbol(for word: String, pronunciationType: PronunciationType = .american) -> String {
        // 这里可以集成一个音标API或数据库
        // 目前返回一个简化的音标表示
        return generateSimplePhonetic(for: word, pronunciationType: pronunciationType)
    }
    
    // 切换发音类型
    func togglePronunciationType(currentType: PronunciationType) -> PronunciationType {
        return currentType == .american ? .british : .american
    }
    
    // 播放单词发音
    func playPronunciation(for word: String, pronunciationType: PronunciationType = .american, completion: @escaping () -> Void = {}) {
        guard !isStopped else { return }
        
        let utterance = AVSpeechUtterance(string: word)
        
        // 根据发音类型选择语言和语音
        switch pronunciationType {
        case .american:
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        case .british:
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        
        // 监听语音合成完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !self.isStopped {
                completion()
            }
        }
    }
    
    // 播放中文文本
    func playChineseText(_ text: String, completion: @escaping () -> Void = {}) {
        guard !isStopped else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 使用中文语音
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        
        // 监听语音合成完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !self.isStopped {
                completion()
            }
        }
    }
    
    // 播放英文文本
    func playEnglishText(_ text: String, completion: @escaping () -> Void = {}) {
        guard !isStopped else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 使用英文语音
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        
        // 监听语音合成完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !self.isStopped {
                completion()
            }
        }
    }
    
    // 停止所有音频播放
    func stopAllAudio() {
        isStopped = true
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // 重新启用音频播放（在新的学习会话开始时调用）
    func resumeAudio() {
        isStopped = false
    }
    
    // 生成简化的音标（实际应用中应该使用真实的音标数据库）
    private func generateSimplePhonetic(for word: String, pronunciationType: PronunciationType = .american) -> String {
        let lowercased = word.lowercased()
        
        // 特殊单词的音标（这些是真实的音标）
        switch lowercased {
        case "creature":
            return pronunciationType == .american ? "ˈkriːtʃər" : "ˈkriːtʃə"
        case "nature":
            return pronunciationType == .american ? "ˈneɪtʃər" : "ˈneɪtʃə"
        case "future":
            return pronunciationType == .american ? "ˈfjuːtʃər" : "ˈfjuːtʃə"
        case "picture":
            return pronunciationType == .american ? "ˈpɪktʃər" : "ˈpɪktʃə"
        case "culture":
            return pronunciationType == .american ? "ˈkʌltʃər" : "ˈkʌltʃə"
        case "adventure":
            return pronunciationType == .american ? "ədˈventʃər" : "ədˈventʃə"
        case "architecture":
            return pronunciationType == .american ? "ˈɑːrkɪtektʃər" : "ˈɑːkɪtektʃə"
        case "literature":
            return pronunciationType == .american ? "ˈlɪtərətʃər" : "ˈlɪtərətʃə"
        case "manufacture":
            return pronunciationType == .american ? "ˌmænjuˈfæktʃər" : "ˌmænjuˈfæktʃə"
        case "temperature":
            return pronunciationType == .american ? "ˈtemprətʃər" : "ˈtemprətʃə"
        default:
            break
        }
        
        // 简单的音标规则（适用于一般单词）
        var phonetic = ""
        var i = 0
        
        while i < lowercased.count {
            let char = lowercased[lowercased.index(lowercased.startIndex, offsetBy: i)]
            
            // 检查双字母组合
            if i < lowercased.count - 1 {
                let nextChar = lowercased[lowercased.index(lowercased.startIndex, offsetBy: i + 1)]
                let twoChar = String(char) + String(nextChar)
                
                switch twoChar {
                case "th":
                    phonetic += "θ"
                    i += 2
                    continue
                case "sh":
                    phonetic += "ʃ"
                    i += 2
                    continue
                case "ch":
                    phonetic += "tʃ"
                    i += 2
                    continue
                case "ou":
                    // 美式和英式发音差异示例
                    phonetic += pronunciationType == .american ? "aʊ" : "əʊ"
                    i += 2
                    continue
                default:
                    break
                }
            }
            
            // 单字母音标（根据发音类型调整）
            switch char {
            case "a":
                phonetic += pronunciationType == .american ? "æ" : "ɑː"
            case "e":
                phonetic += "e"
            case "i":
                phonetic += "ɪ"
            case "o":
                phonetic += pronunciationType == .american ? "oʊ" : "əʊ"
            case "u":
                phonetic += pronunciationType == .american ? "ju" : "juː"
            case "r":
                // 检查r的位置，词尾的r在英式中通常不发音
                let isAtEnd = i == lowercased.count - 1
                if isAtEnd {
                    // 词尾的r在英式中不发音，在美式中可能发音
                    phonetic += pronunciationType == .american ? "r" : ""
                } else {
                    // 词中或词首的r
                    phonetic += "r"
                }
            default:
                phonetic += String(char)
            }
            
            i += 1
        }
        
        // 不添加发音类型标识，让界面组件处理
        return phonetic
    }
}
