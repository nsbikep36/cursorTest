import Foundation
import SwiftUI

// 方块类型枚举
enum BlockType: Int, CaseIterable {
    case red = 0
    case blue = 1
    case yellow = 2
    case green = 3
    case purple = 4
    case orange = 5
    
    var emoji: String {
        switch self {
        case .red: return "🔴"
        case .blue: return "🔵"
        case .yellow: return "🟡"
        case .green: return "🟢"
        case .purple: return "🟣"
        case .orange: return "🟠"
        }
    }
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .yellow: return .yellow
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}

// 游戏状态
enum GameState {
    case playing
    case paused
    case gameOver
    case levelComplete
}

// 道具类型
enum PowerUpType {
    case bomb
    case rainbow
    case shuffle
    
    var emoji: String {
        switch self {
        case .bomb: return "💣"
        case .rainbow: return "🌈"
        case .shuffle: return "🔄"
        }
    }
    
    var description: String {
        switch self {
        case .bomb: return "炸弹 - 清除周围方块"
        case .rainbow: return "彩虹 - 清除同色方块"
        case .shuffle: return "重排 - 重新排列方块"
        }
    }
}

// 游戏位置
struct Position: Equatable {
    let row: Int
    let col: Int
}

// 游戏逻辑类
class GameLogic: ObservableObject {
    @Published var board: [[BlockType?]] = []
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var moves: Int = 30
    @Published var target: Int = 1000
    @Published var gameState: GameState = .playing
    @Published var selectedPosition: Position?
    @Published var activePowerUp: PowerUpType?
    @Published var powerUps: [PowerUpType: Int] = [
        .bomb: 3,
        .rainbow: 2,
        .shuffle: 1
    ]
    @Published var hintText: String = "连接3个或更多相同的方块来消除它们！"
    
    private let boardSize = 8
    private let audioManager = AudioManager.shared
    
    init() {
        initializeGame()
    }
    
    func initializeGame() {
        createBoard()
        updateProgress()
        showHint("连接3个或更多相同的方块来消除它们！")
    }
    
    private func createBoard() {
        board = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                var blockType: BlockType
                repeat {
                    blockType = BlockType.allCases.randomElement()!
                } while hasInitialMatch(at: Position(row: row, col: col), with: blockType)
                
                board[row][col] = blockType
            }
        }
    }
    
    private func hasInitialMatch(at position: Position, with blockType: BlockType) -> Bool {
        // 检查水平匹配
        if position.col >= 2 &&
           board[position.row][position.col - 1] == blockType &&
           board[position.row][position.col - 2] == blockType {
            return true
        }
        
        // 检查垂直匹配
        if position.row >= 2 &&
           board[position.row - 1][position.col] == blockType &&
           board[position.row - 2][position.col] == blockType {
            return true
        }
        
        return false
    }
    
    func handleCellTap(at position: Position) {
        guard gameState == .playing && moves > 0 else { return }
        
        // 如果有激活的道具
        if let powerUp = activePowerUp {
            usePowerUp(powerUp, at: position)
            return
        }
        
        // 如果已经选中了一个方块
        if let selected = selectedPosition {
            if selected == position {
                // 取消选择
                selectedPosition = nil
            } else if isAdjacent(selected, position) {
                // 尝试交换
                attemptSwap(from: selected, to: position)
                selectedPosition = nil
            } else {
                // 选择新的方块
                selectedPosition = position
                audioManager.playSelectSound()
            }
        } else {
            // 选择方块
            selectedPosition = position
            audioManager.playSelectSound()
        }
    }
    
    private func isAdjacent(_ pos1: Position, _ pos2: Position) -> Bool {
        let rowDiff = abs(pos1.row - pos2.row)
        let colDiff = abs(pos1.col - pos2.col)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }
    
    private func attemptSwap(from: Position, to: Position) {
        guard isValidPosition(from) && isValidPosition(to) else { return }
        
        // 交换方块
        let temp = board[from.row][from.col]
        board[from.row][from.col] = board[to.row][to.col]
        board[to.row][to.col] = temp
        
        // 检查是否有匹配
        let matches = findMatches()
        if !matches.isEmpty {
            // 有匹配，消耗移动次数
            moves -= 1
            audioManager.playSwapSound()
            processMatches(matches)
        } else {
            // 没有匹配，交换回去
            let temp = board[from.row][from.col]
            board[from.row][from.col] = board[to.row][to.col]
            board[to.row][to.col] = temp
            showHint("无法进行匹配，请尝试其他组合！")
        }
    }
    
    private func findMatches() -> Set<Position> {
        var matches = Set<Position>()
        
        // 查找水平匹配
        for row in 0..<boardSize {
            var count = 1
            var currentType = board[row][0]
            
            for col in 1..<boardSize {
                if board[row][col] == currentType && currentType != nil {
                    count += 1
                } else {
                    if count >= 3 {
                        for i in (col - count)..<col {
                            matches.insert(Position(row: row, col: i))
                        }
                    }
                    count = 1
                    currentType = board[row][col]
                }
            }
            
            if count >= 3 {
                for i in (boardSize - count)..<boardSize {
                    matches.insert(Position(row: row, col: i))
                }
            }
        }
        
        // 查找垂直匹配
        for col in 0..<boardSize {
            var count = 1
            var currentType = board[0][col]
            
            for row in 1..<boardSize {
                if board[row][col] == currentType && currentType != nil {
                    count += 1
                } else {
                    if count >= 3 {
                        for i in (row - count)..<row {
                            matches.insert(Position(row: i, col: col))
                        }
                    }
                    count = 1
                    currentType = board[row][col]
                }
            }
            
            if count >= 3 {
                for i in (boardSize - count)..<boardSize {
                    matches.insert(Position(row: i, col: col))
                }
            }
        }
        
        return matches
    }
    
    private func processMatches(_ matches: Set<Position>) {
        // 播放匹配音效
        audioManager.playMatchSound()
        
        // 计算得分
        let baseScore = matches.count * 10
        let multiplier = max(1, matches.count - 2)
        let earnedScore = baseScore * multiplier
        score += earnedScore
        
        // 清除匹配的方块
        for position in matches {
            board[position.row][position.col] = nil
        }
        
        // 应用重力
        applyGravity()
        
        // 填充空白
        fillEmptySpaces()
        
        // 检查是否有新的匹配
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newMatches = self.findMatches()
            if !newMatches.isEmpty {
                self.processMatches(newMatches)
            } else {
                self.checkGameState()
            }
        }
        
        updateProgress()
        showHint("太棒了！消除了 \(matches.count) 个方块，获得 \(earnedScore) 分！")
    }
    
    private func applyGravity() {
        for col in 0..<boardSize {
            var writeIndex = boardSize - 1
            
            for row in stride(from: boardSize - 1, through: 0, by: -1) {
                if board[row][col] != nil {
                    if row != writeIndex {
                        board[writeIndex][col] = board[row][col]
                        board[row][col] = nil
                    }
                    writeIndex -= 1
                }
            }
        }
    }
    
    private func fillEmptySpaces() {
        for col in 0..<boardSize {
            for row in 0..<boardSize {
                if board[row][col] == nil {
                    board[row][col] = BlockType.allCases.randomElement()!
                }
            }
        }
    }
    
    private func usePowerUp(_ powerUp: PowerUpType, at position: Position) {
        guard let count = powerUps[powerUp], count > 0 else { return }
        
        powerUps[powerUp] = count - 1
        activePowerUp = nil
        
        switch powerUp {
        case .bomb:
            audioManager.playBombSound()
            useBomb(at: position)
        case .rainbow:
            audioManager.playRainbowSound()
            useRainbow(at: position)
        case .shuffle:
            audioManager.playShuffleSound()
            shuffleBoard()
        }
    }
    
    private func useBomb(at position: Position) {
        var affectedPositions = Set<Position>()
        
        for rowOffset in -1...1 {
            for colOffset in -1...1 {
                let newRow = position.row + rowOffset
                let newCol = position.col + colOffset
                let newPosition = Position(row: newRow, col: newCol)
                
                if isValidPosition(newPosition) {
                    affectedPositions.insert(newPosition)
                }
            }
        }
        
        processMatches(affectedPositions)
        showHint("炸弹爆炸！清除了 \(affectedPositions.count) 个方块！")
    }
    
    private func useRainbow(at position: Position) {
        guard let targetType = board[position.row][position.col] else { return }
        
        var affectedPositions = Set<Position>()
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if board[row][col] == targetType {
                    affectedPositions.insert(Position(row: row, col: col))
                }
            }
        }
        
        processMatches(affectedPositions)
        showHint("彩虹效果！清除了所有 \(targetType.emoji) 方块！")
    }
    
    private func shuffleBoard() {
        var allBlocks: [BlockType] = []
        
        // 收集所有方块
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let block = board[row][col] {
                    allBlocks.append(block)
                }
            }
        }
        
        // 打乱数组
        allBlocks.shuffle()
        
        // 重新分配
        var index = 0
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                board[row][col] = allBlocks[index]
                index += 1
            }
        }
        
        showHint("重新排列完成！寻找新的匹配机会！")
    }
    
    func activatePowerUp(_ powerUp: PowerUpType) {
        guard let count = powerUps[powerUp], count > 0 else { return }
        
        if activePowerUp == powerUp {
            activePowerUp = nil
            showHint("取消道具选择")
        } else {
            activePowerUp = powerUp
            showHint("选择目标位置使用 \(powerUp.description)")
        }
    }
    
    func pauseGame() {
        gameState = gameState == .paused ? .playing : .paused
    }
    
    func restartGame() {
        score = 0
        moves = 30
        level = 1
        target = 1000
        gameState = .playing
        selectedPosition = nil
        activePowerUp = nil
        powerUps = [
            .bomb: 3,
            .rainbow: 2,
            .shuffle: 1
        ]
        initializeGame()
    }
    
    private func checkGameState() {
        if score >= target {
            // 关卡完成
            gameState = .levelComplete
            audioManager.playLevelCompleteSound()
            showHint("恭喜完成关卡！")
        } else if moves <= 0 {
            // 游戏结束
            gameState = .gameOver
            audioManager.playGameOverSound()
            showHint("游戏结束！再试一次吧！")
        }
    }
    
    func nextLevel() {
        level += 1
        target = 1000 + (level - 1) * 500
        moves = 30
        gameState = .playing
        
        // 奖励道具
        powerUps[.bomb] = (powerUps[.bomb] ?? 0) + 1
        if level % 3 == 0 {
            powerUps[.rainbow] = (powerUps[.rainbow] ?? 0) + 1
        }
        if level % 5 == 0 {
            powerUps[.shuffle] = (powerUps[.shuffle] ?? 0) + 1
        }
        
        initializeGame()
        showHint("欢迎来到第 \(level) 关！目标：\(target) 分")
    }
    
    private func updateProgress() {
        // 计算进度百分比
        let progress = min(1.0, Double(score) / Double(target))
        // 这里可以更新UI进度条
    }
    
    private func showHint(_ text: String) {
        hintText = text
    }
    
    private func isValidPosition(_ position: Position) -> Bool {
        return position.row >= 0 && position.row < boardSize && 
               position.col >= 0 && position.col < boardSize
    }
}