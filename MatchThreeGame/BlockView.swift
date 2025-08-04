import SwiftUI

struct BlockView: View {
    let blockType: BlockType?
    let isSelected: Bool
    let cellSize: CGFloat
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: cellSize * 0.2)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cellSize * 0.2)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
            
            // 方块内容
            if let blockType = blockType {
                VStack(spacing: 2) {
                    // 主要emoji
                    Text(blockType.emoji)
                        .font(.system(size: cellSize * 0.4))
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                    
                    // 小装饰点
                    Circle()
                        .fill(blockType.color.opacity(0.3))
                        .frame(width: cellSize * 0.1, height: cellSize * 0.1)
                }
            } else {
                // 空方块占位符
                RoundedRectangle(cornerRadius: cellSize * 0.1)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scale)
        .onAppear {
            // 出现动画
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double.random(in: 0...0.3))) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private var backgroundColor: Color {
        if let blockType = blockType {
            return blockType.color.opacity(0.15)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.orange
        } else if let blockType = blockType {
            return blockType.color.opacity(0.4)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// 扩展BlockView添加动画方法
extension BlockView {
    func playMatchAnimation() -> some View {
        self
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 1.2
                    rotation = 360
                }
                
                withAnimation(.easeInOut(duration: 0.2).delay(0.3)) {
                    opacity = 0
                    scale = 0.1
                }
            }
    }
    
    func playFallAnimation(delay: Double = 0) -> some View {
        self
            .onAppear {
                scale = 0.1
                opacity = 0
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
    
    func playSwapAnimation() -> some View {
        self
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.1
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.2)) {
                    scale = 1.0
                }
            }
    }
}

struct BlockView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(BlockType.allCases, id: \.self) { blockType in
                    BlockView(blockType: blockType, isSelected: false, cellSize: 50)
                }
            }
            
            HStack(spacing: 10) {
                BlockView(blockType: .red, isSelected: true, cellSize: 50)
                BlockView(blockType: nil, isSelected: false, cellSize: 50)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}