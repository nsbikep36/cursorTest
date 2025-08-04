import SwiftUI

struct ContentView: View {
    @StateObject private var gameLogic = GameLogic()
    @State private var showGame = false
    
    var body: some View {
        NavigationView {
            if showGame {
                GameView(gameLogic: gameLogic)
            } else {
                WelcomeView(showGame: $showGame)
            }
        }
        .navigationBarHidden(true)
    }
}

struct WelcomeView: View {
    @Binding var showGame: Bool
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 游戏标题
                VStack(spacing: 10) {
                    Text("🍭")
                        .font(.system(size: 100))
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: true)
                    
                    Text("消消乐")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    
                    Text("Match Three Game")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 100)
                
                Spacer()
                
                // 游戏特色说明
                VStack(spacing: 15) {
                    GameFeatureRow(icon: "🎯", title: "经典玩法", description: "连接3个或更多相同方块")
                    GameFeatureRow(icon: "💎", title: "精美视觉", description: "流畅动画和粒子效果")
                    GameFeatureRow(icon: "🚀", title: "道具系统", description: "炸弹、彩虹、重排道具")
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // 开始游戏按钮
                Button(action: {
                    withAnimation(.spring()) {
                        showGame = true
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("开始游戏")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.orange)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
                .padding(.bottom, 80)
            }
        }
    }
}

struct GameFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Text(icon)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(BlurView(style: .systemUltraThinMaterial))
        )
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}