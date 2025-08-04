import SwiftUI

struct GameView: View {
    @ObservedObject var gameLogic: GameLogic
    @State private var showOverlay = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.3),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 游戏头部
                GameHeaderView(gameLogic: gameLogic)
                
                // 主要游戏区域
                HStack(spacing: 20) {
                    // 游戏棋盘
                    GameBoard(gameLogic: gameLogic)
                        .frame(maxWidth: .infinity)
                    
                    // 侧边栏
                    GameSidebarView(gameLogic: gameLogic)
                        .frame(width: 120)
                }
                .padding(.horizontal, 20)
                
                // 底部提示
                HintView(text: gameLogic.hintText)
            }
            
            // 游戏结束/关卡完成覆盖层
            if gameLogic.gameState == .gameOver || gameLogic.gameState == .levelComplete {
                GameOverlayView(gameLogic: gameLogic)
            }
            
            // 暂停覆盖层
            if gameLogic.gameState == .paused {
                PauseOverlayView(gameLogic: gameLogic)
            }
        }
    }
}

struct GameHeaderView: View {
    @ObservedObject var gameLogic: GameLogic
    
    var body: some View {
        VStack(spacing: 15) {
            // 游戏标题
            HStack {
                Text("🍭 消消乐")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 游戏统计
            HStack(spacing: 10) {
                StatCard(label: "得分", value: "\(gameLogic.score)", color: .blue)
                StatCard(label: "关卡", value: "\(gameLogic.level)", color: .green)
                StatCard(label: "移动", value: "\(gameLogic.moves)", color: .orange)
                StatCard(label: "目标", value: "\(gameLogic.target)", color: .purple)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct GameSidebarView: View {
    @ObservedObject var gameLogic: GameLogic
    
    var body: some View {
        VStack(spacing: 15) {
            // 进度条
            ProgressView(
                value: Double(gameLogic.score),
                total: Double(gameLogic.target)
            )
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .scaleEffect(0.8)
            
            Text("\(gameLogic.score)/\(gameLogic.target)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            // 道具
            VStack(spacing: 10) {
                Text("道具")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ForEach([PowerUpType.bomb, .rainbow, .shuffle], id: \.self) { powerUp in
                    PowerUpButton(
                        powerUp: powerUp,
                        count: gameLogic.powerUps[powerUp] ?? 0,
                        isActive: gameLogic.activePowerUp == powerUp
                    ) {
                        gameLogic.activatePowerUp(powerUp)
                    }
                }
            }
            
            Spacer()
            
            // 游戏控制按钮
            VStack(spacing: 8) {
                ControlButton(
                    icon: gameLogic.gameState == .paused ? "play.fill" : "pause.fill",
                    action: { gameLogic.pauseGame() }
                )
                
                ControlButton(
                    icon: "arrow.clockwise",
                    action: { gameLogic.restartGame() }
                )
            }
        }
        .padding(.vertical, 10)
    }
}

struct PowerUpButton: View {
    let powerUp: PowerUpType
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(powerUp.emoji)
                    .font(.title3)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.red))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isActive ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .disabled(count <= 0)
        .opacity(count > 0 ? 1.0 : 0.5)
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                )
        }
    }
}

struct HintView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal, 20)
    }
}

struct GameOverlayView: View {
    @ObservedObject var gameLogic: GameLogic
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(gameLogic.gameState == .levelComplete ? "🎉" : "😞")
                    .font(.system(size: 80))
                
                Text(gameLogic.gameState == .levelComplete ? "关卡完成！" : "游戏结束")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(gameLogic.gameState == .levelComplete ? 
                     "恭喜完成第 \(gameLogic.level) 关！" : 
                     "最终得分：\(gameLogic.score)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 20) {
                    if gameLogic.gameState == .levelComplete {
                        Button("下一关") {
                            gameLogic.nextLevel()
                        }
                        .buttonStyle(GameButtonStyle(color: .green))
                    }
                    
                    Button("重新开始") {
                        gameLogic.restartGame()
                    }
                    .buttonStyle(GameButtonStyle(color: .blue))
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(BlurView(style: .systemUltraThinMaterial))
            )
        }
    }
}

struct PauseOverlayView: View {
    @ObservedObject var gameLogic: GameLogic
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("⏸️")
                    .font(.system(size: 80))
                
                Text("游戏暂停")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Button("继续游戏") {
                    gameLogic.pauseGame()
                }
                .buttonStyle(GameButtonStyle(color: .green))
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(BlurView(style: .systemUltraThinMaterial))
            )
        }
    }
}

struct GameButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(color)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(gameLogic: GameLogic())
    }
}