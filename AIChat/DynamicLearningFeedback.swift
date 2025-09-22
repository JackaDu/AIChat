import SwiftUI
import Combine

// MARK: - 动态学习反馈系统
struct DynamicLearningFeedback: View {
    let isCorrect: Bool
    let memoryStrength: Double // 0.0 - 1.0
    let streakCount: Int
    @State private var showParticles = false
    @State private var curveAnimationProgress: Double = 0.0
    @State private var memoryPointScale: Double = 1.0
    
    var body: some View {
        ZStack {
            // 背景遗忘曲线
            ForgettingCurveBackground(
                memoryStrength: memoryStrength,
                animationProgress: curveAnimationProgress
            )
            
            // 粒子效果层
            if showParticles && isCorrect {
                ParticleEffectView()
            }
            
            // 记忆强度指示器
            MemoryStrengthIndicator(
                strength: memoryStrength,
                scale: memoryPointScale,
                isCorrect: isCorrect
            )
            
            // 连击效果
            if streakCount > 1 {
                StreakEffectView(count: streakCount)
            }
        }
        .onAppear {
            startFeedbackAnimation()
        }
    }
    
    private func startFeedbackAnimation() {
        // 曲线动画
        withAnimation(.easeInOut(duration: 1.5)) {
            curveAnimationProgress = 1.0
        }
        
        // 记忆点动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
            memoryPointScale = isCorrect ? 1.3 : 0.8
        }
        
        // 粒子效果
        if isCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showParticles = true
            }
        }
        
        // 重置动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                memoryPointScale = 1.0
                showParticles = false
                curveAnimationProgress = 0.0
            }
        }
    }
}

// MARK: - 遗忘曲线背景
struct ForgettingCurveBackground: View {
    let memoryStrength: Double
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景网格
                DynamicCurveGrid()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                
                // 主遗忘曲线
                DynamicForgettingCurvePath(
                    memoryStrength: memoryStrength,
                    animationProgress: animationProgress
                )
                .stroke(
                    LinearGradient(
                        colors: memoryStrength > 0.7 ? [.green, .blue] : 
                               memoryStrength > 0.4 ? [.yellow, .orange] : [.red, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .shadow(color: .blue.opacity(0.3), radius: 5)
                
                // 理想记忆曲线（虚线）
                IdealMemoryCurve()
                    .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 动态遗忘曲线路径
struct DynamicForgettingCurvePath: Shape {
    let memoryStrength: Double
    let animationProgress: Double
    
    var animatableData: Double {
        get { animationProgress }
        set { }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let startPoint = CGPoint(x: 0, y: rect.height * (1 - memoryStrength))
        path.move(to: startPoint)
        
        let points = 50
        for i in 0...Int(Double(points) * animationProgress) {
            let x = rect.width * Double(i) / Double(points)
            let normalizedX = Double(i) / Double(points)
            
            // 艾宾浩斯遗忘曲线公式: R = e^(-t/S)
            // R: 记忆保持率, t: 时间, S: 记忆强度
            let timeDecay = exp(-normalizedX * 5 / max(memoryStrength, 0.1))
            let y = rect.height * (1 - memoryStrength * timeDecay)
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - 理想记忆曲线
struct IdealMemoryCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.15))
        return path
    }
}

// MARK: - 动态网格背景
struct DynamicCurveGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 水平线
        for i in 0...4 {
            let y = rect.height * Double(i) / 4
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        // 垂直线
        for i in 0...6 {
            let x = rect.width * Double(i) / 6
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        return path
    }
}

// MARK: - 记忆强度指示器
struct MemoryStrengthIndicator: View {
    let strength: Double
    let scale: Double
    let isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 记忆强度圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: strength)
                    .stroke(
                        LinearGradient(
                            colors: strength > 0.7 ? [.green, .blue] :
                                   strength > 0.4 ? [.yellow, .orange] : [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.6), value: strength)
                
                // 中心图标
                Text(isCorrect ? "🧠" : "💭")
                    .font(.title2)
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: scale)
            }
            
            // 强度百分比
            Text("\(Int(strength * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(
                    strength > 0.7 ? .green :
                    strength > 0.4 ? .orange : .red
                )
        }
    }
}

// MARK: - 粒子效果
struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<20).map { _ in
            Particle(
                id: UUID(),
                x: Double.random(in: -50...50),
                y: Double.random(in: -50...50),
                size: Double.random(in: 4...12),
                color: [.yellow, .orange, .green, .blue, .purple].randomElement()!,
                opacity: 1.0,
                scale: 1.0
            )
        }
        
        // 动画粒子
        withAnimation(.easeOut(duration: 2.0)) {
            for i in particles.indices {
                particles[i].x += Double.random(in: -100...100)
                particles[i].y += Double.random(in: -100...100)
                particles[i].opacity = 0.0
                particles[i].scale = 0.0
            }
        }
    }
}

// MARK: - 粒子数据模型
struct Particle {
    let id: UUID
    var x: Double
    var y: Double
    let size: Double
    let color: Color
    var opacity: Double
    var scale: Double
}

// MARK: - 连击效果
struct StreakEffectView: View {
    let count: Int
    @State private var bounceScale: Double = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<min(count, 5), id: \.self) { _ in
                    Text("⭐")
                        .font(.title3)
                        .scaleEffect(bounceScale)
                        .rotationEffect(.degrees(rotationAngle))
                }
            }
            
            Text("\(count)连击!")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(bounceScale)
        }
        .onAppear {
            startBounceAnimation()
        }
    }
    
    private func startBounceAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.3).repeatCount(3)) {
            bounceScale = 1.3
        }
        
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                bounceScale = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        DynamicLearningFeedback(
            isCorrect: true,
            memoryStrength: 0.75,
            streakCount: 3
        )
        
        DynamicLearningFeedback(
            isCorrect: false,
            memoryStrength: 0.35,
            streakCount: 0
        )
    }
    .padding()
}
