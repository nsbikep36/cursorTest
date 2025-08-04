import SwiftUI

struct PowerUpView: View {
    @ObservedObject var gameLogic: GameLogic
    @State private var showPowerUpInfo = false
    @State private var selectedPowerUp: PowerUpType?
    
    var body: some View {
        VStack(spacing: 15) {
            // 道具标题
            HStack {
                Text("🎮 道具")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    showPowerUpInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            // 道具列表
            VStack(spacing: 10) {
                ForEach([PowerUpType.bomb, .rainbow, .shuffle], id: \.self) { powerUp in
                    PowerUpRow(
                        powerUp: powerUp,
                        count: gameLogic.powerUps[powerUp] ?? 0,
                        isActive: gameLogic.activePowerUp == powerUp
                    ) {
                        gameLogic.activatePowerUp(powerUp)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
        )
        .sheet(isPresented: $showPowerUpInfo) {
            PowerUpInfoView()
        }
    }
}

struct PowerUpRow: View {
    let powerUp: PowerUpType
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(powerUp.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(powerUp.description)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("剩余: \(count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .disabled(count <= 0)
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.blue.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(count > 0 ? 1.0 : 0.5)
    }
}

struct PowerUpInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🎮 道具说明")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    PowerUpInfoCard(
                        emoji: "💣",
                        title: "炸弹",
                        description: "清除选中位置周围3x3区域内的所有方块"
                    )
                    
                    PowerUpInfoCard(
                        emoji: "🌈",
                        title: "彩虹",
                        description: "清除棋盘上所有与选中方块相同颜色的方块"
                    )
                    
                    PowerUpInfoCard(
                        emoji: "🔀",
                        title: "重排",
                        description: "重新随机排列整个棋盘上的所有方块"
                    )
                }
                
                Spacer()
                
                Text("💡 提示：道具可以通过消除更多方块或完成关卡获得")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct PowerUpInfoCard: View {
    let emoji: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Text(emoji)
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct PowerUpView_Previews: PreviewProvider {
    static var previews: some View {
        PowerUpView(gameLogic: GameLogic())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}