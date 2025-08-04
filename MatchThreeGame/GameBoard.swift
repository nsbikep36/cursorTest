import SwiftUI

struct GameBoard: View {
    @ObservedObject var gameLogic: GameLogic
    @State private var dragOffset = CGSize.zero
    @State private var dragStartPosition: Position?
    
    private let gridSpacing: CGFloat = 4
    private let boardPadding: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height) - boardPadding * 2
            let cellSize = (boardSize - gridSpacing * 7) / 8
            
            VStack(spacing: gridSpacing) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<8, id: \.self) { col in
                            let position = Position(row: row, col: col)
                            
                            BlockView(
                                blockType: gameLogic.board[row][col],
                                isSelected: gameLogic.selectedPosition == position,
                                cellSize: cellSize
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    gameLogic.handleCellTap(at: position)
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onChanged { value in
                                        if dragStartPosition == nil {
                                            dragStartPosition = position
                                        }
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        handleDragEnd(
                                            startPosition: position,
                                            translation: value.translation,
                                            cellSize: cellSize
                                        )
                                        dragOffset = .zero
                                        dragStartPosition = nil
                                    }
                            )
                            .offset(
                                dragStartPosition == position ? dragOffset : .zero
                            )
                            .zIndex(dragStartPosition == position ? 1 : 0)
                        }
                    }
                }
            }
            .frame(width: boardSize, height: boardSize)
            .padding(boardPadding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .center()
        }
    }
    
    private func handleDragEnd(startPosition: Position, translation: CGSize, cellSize: CGFloat) {
        let threshold = cellSize * 0.5
        
        var targetPosition = startPosition
        
        if abs(translation.x) > abs(translation.y) {
            // 水平拖拽
            if translation.x > threshold && startPosition.col < 7 {
                targetPosition = Position(row: startPosition.row, col: startPosition.col + 1)
            } else if translation.x < -threshold && startPosition.col > 0 {
                targetPosition = Position(row: startPosition.row, col: startPosition.col - 1)
            }
        } else {
            // 垂直拖拽
            if translation.y > threshold && startPosition.row < 7 {
                targetPosition = Position(row: startPosition.row + 1, col: startPosition.col)
            } else if translation.y < -threshold && startPosition.row > 0 {
                targetPosition = Position(row: startPosition.row - 1, col: startPosition.col)
            }
        }
        
        if targetPosition != startPosition {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                gameLogic.selectedPosition = startPosition
                gameLogic.handleCellTap(at: targetPosition)
            }
        }
    }
}

extension View {
    func center() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
}

struct GameBoard_Previews: PreviewProvider {
    static var previews: some View {
        GameBoard(gameLogic: GameLogic())
            .previewLayout(.fixed(width: 400, height: 400))
    }
}