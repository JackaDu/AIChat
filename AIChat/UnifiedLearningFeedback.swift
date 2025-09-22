import SwiftUI
import Combine

// MARK: - 统一学习反馈系统
struct UnifiedLearningFeedback: View {
    let isCorrect: Bool
    let memoryStrength: Double // 0.0 - 1.0
    let streakCount: Int
    let onComplete: () -> Void
    
    @State private var showParticles = false
    @State private var curveAnimationProgress: Double = 0.0
    @State private var memoryPointScale: Double = 1.0
    @State private var showFeedbackText = false
    @State private var cardScale: Double = 1.0
    @State private var cardRotation: Double = 0.0
    @State private var showStreakEffect = false
    
    var body: some View {
        ZStack {
            // 1. 背景遗忘曲线动画
            UnifiedForgettingCurveBackground(
                memoryStrength: memoryStrength,
                animationProgress: curveAnimationProgress,
                isCorrect: isCorrect
            )
            
            VStack(spacing: 24) {
                // 2. 主要反馈区域
                VStack(spacing: 16) {
                    // 结果图标
                    ZStack {
                        // 背景圆圈
                        Circle()
                            .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .scaleEffect(cardScale)
                            .rotationEffect(.degrees(cardRotation))
                        
                        // 主图标
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(isCorrect ? .green : .red)
                            .scaleEffect(showFeedbackText ? 1.0 : 0.5)
                            .animation(.spring(duration: 0.6, bounce: 0.4).delay(0.3), value: showFeedbackText)
                        
                        // 连击星星效果
                        if showStreakEffect && streakCount > 1 {
                            ForEach(0..<min(streakCount, 5), id: \.self) { index in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                    .offset(
                                        x: cos(Double(index) * 2 * .pi / 5) * 40,
                                        y: sin(Double(index) * 2 * .pi / 5) * 40
                                    )
                                    .scaleEffect(showStreakEffect ? 1.0 : 0.1)
                                    .animation(.spring(duration: 0.5, bounce: 0.6).delay(0.6 + Double(index) * 0.1), value: showStreakEffect)
                            }
                        }
                    }
                    
                    // 简化的反馈文本
                    Text(isCorrect ? "回答正确！🎉" : "继续努力！💪")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(isCorrect ? .green : .orange)
                    .opacity(showFeedbackText ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.4).delay(0.5), value: showFeedbackText)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isCorrect ? .green.opacity(0.3) : .orange.opacity(0.3), lineWidth: 2)
                        )
                )
                .scaleEffect(cardScale)
                .rotationEffect(.degrees(cardRotation))
                
                // 3. 记忆强度指示器
                UnifiedMemoryStrengthIndicator(
                    strength: memoryStrength,
                    scale: memoryPointScale,
                    isCorrect: isCorrect
                )
                
                // 4. 继续按钮
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("继续")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(showFeedbackText ? 1.0 : 0.8)
                .animation(.spring(duration: 0.4, bounce: 0.2).delay(1.2), value: showFeedbackText)
            }
            
            // 5. 粒子效果层
            if showParticles && isCorrect {
                UnifiedParticleEffect()
            }
        }
        .onAppear {
            startUnifiedFeedbackAnimation()
        }
    }
    
    private func startUnifiedFeedbackAnimation() {
        // 1. 立即的卡片动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            cardScale = isCorrect ? 1.05 : 0.98
            cardRotation = isCorrect ? 2 : -2
        }
        
        // 2. 触觉反馈
        if isCorrect {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
        
        // 3. 曲线动画
        withAnimation(.easeInOut(duration: 1.5).delay(0.2)) {
            curveAnimationProgress = 1.0
        }
        
        // 4. 记忆点动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.4).delay(0.3)) {
            memoryPointScale = isCorrect ? 1.4 : 0.7
        }
        
        // 5. 显示文本
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showFeedbackText = true
        }
        
        // 6. 粒子效果
        if isCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showParticles = true
            }
        }
        
        // 7. 连击效果
        if streakCount > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showStreakEffect = true
                // 连击震动
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
        }
        
        // 8. 恢复动画（1.5秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                cardScale = 1.0
                cardRotation = 0.0
                memoryPointScale = 1.0
            }
        }
        
        // 9. 清理效果（3秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showParticles = false
            showStreakEffect = false
            curveAnimationProgress = 0.0
        }
    }
}

// MARK: - 统一遗忘曲线背景
struct UnifiedForgettingCurveBackground: View {
    let memoryStrength: Double
    let animationProgress: Double
    let isCorrect: Bool
    
    var body: some View {
        ZStack {
            // 背景网格
            UnifiedCurveGrid()
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            
            // 主遗忘曲线
            UnifiedForgettingCurvePath(
                memoryStrength: memoryStrength,
                animationProgress: animationProgress
            )
            .trim(from: 0, to: animationProgress)
            .stroke(
                LinearGradient(
                    colors: curveColors,
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            
            // 记忆点
            Circle()
                .fill(isCorrect ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .position(x: 50 + memoryStrength * 250, y: 100 - memoryStrength * 60)
                .shadow(color: isCorrect ? .green.opacity(0.6) : .orange.opacity(0.6), radius: 4)
        }
        .frame(height: 120)
    }
    
    private var curveColors: [Color] {
        if memoryStrength > 0.7 {
            return [.green, .blue]
        } else if memoryStrength > 0.4 {
            return [.yellow, .orange]
        } else {
            return [.red, .purple]
        }
    }
}

// MARK: - 统一记忆强度指示器
struct UnifiedMemoryStrengthIndicator: View {
    let strength: Double
    let scale: Double
    let isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("记忆强度")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: strength)
                    .stroke(
                        LinearGradient(
                            colors: strengthColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(scale)
                
                // 百分比文本
                Text("\(Int(strength * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private var strengthColors: [Color] {
        if strength > 0.7 {
            return [.green, .blue]
        } else if strength > 0.4 {
            return [.yellow, .orange]
        } else {
            return [.red, .pink]
        }
    }
}

// MARK: - 统一粒子效果
struct UnifiedParticleEffect: View {
    @State private var particles: [ParticleData] = []
    
    struct ParticleData: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var scale: Double
        var opacity: Double
        var rotation: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: ["star.fill", "sparkle", "circle.fill"].randomElement()!)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.random)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        for _ in 0..<15 {
            let particle = ParticleData(
                x: Double.random(in: 50...300),
                y: Double.random(in: 100...400),
                scale: Double.random(in: 0.5...1.5),
                opacity: 1.0,
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
        // 动画粒子
        withAnimation(.easeOut(duration: 2.0)) {
            for i in particles.indices {
                particles[i].y -= Double.random(in: 50...150)
                particles[i].opacity = 0.0
                particles[i].scale *= 0.5
                particles[i].rotation += Double.random(in: 180...360)
            }
        }
    }
}

// MARK: - 扩展色彩随机选择
extension Color {
    static var random: Color {
        let colors: [Color] = [.blue, .green, .yellow, .orange, .pink, .purple]
        return colors.randomElement() ?? .blue
    }
}

// MARK: - 统一曲线路径
struct UnifiedForgettingCurvePath: Shape {
    let memoryStrength: Double
    let animationProgress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let startPoint = CGPoint(x: rect.minX + 20, y: rect.midY)
        path.move(to: startPoint)
        
        // 艾宾浩斯遗忘曲线
        for i in 0...100 {
            let progress = Double(i) / 100.0
            let x = rect.minX + 20 + progress * (rect.width - 40)
            
            // 遗忘曲线公式：R = e^(-t/S) 其中 R是记忆强度，t是时间，S是记忆强度因子
            let forgettingFactor = exp(-progress * 3.0)
            let adjustedStrength = memoryStrength * forgettingFactor + (1 - memoryStrength) * 0.1
            let y = rect.maxY - 20 - adjustedStrength * (rect.height - 40)
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - 统一网格背景
struct UnifiedCurveGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 垂直线
        for i in 0...5 {
            let x = rect.minX + CGFloat(i) * rect.width / 5
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        
        // 水平线
        for i in 0...3 {
            let y = rect.minY + CGFloat(i) * rect.height / 3
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        
        return path
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        UnifiedLearningFeedback(
            isCorrect: true,
            memoryStrength: 0.75,
            streakCount: 3,
            onComplete: {}
        )
        
        UnifiedLearningFeedback(
            isCorrect: false,
            memoryStrength: 0.35,
            streakCount: 0,
            onComplete: {}
        )
    }
    .padding()
}
