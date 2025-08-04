class MatchThreeGame {
    constructor() {
        this.boardSize = 8;
        this.board = [];
        this.selectedCell = null;
        this.score = 0;
        this.level = 1;
        this.moves = 30;
        this.target = 1000;
        this.gameRunning = true;
        this.isPaused = false;
        this.soundEnabled = true;
        this.activePowerUp = null;
        
        // 道具数量
        this.powerUps = {
            bomb: 3,
            rainbow: 2,
            shuffle: 1
        };
        
        // 方块类型（使用emoji表示）
        this.blockTypes = ['🔴', '🔵', '🟡', '🟢', '🟣', '🟠'];
        
        this.initializeGame();
        this.bindEvents();
    }
    
    initializeGame() {
        this.createBoard();
        this.renderBoard();
        this.updateUI();
        this.showHint("连接3个或更多相同的方块来消除它们！");
    }
    
    createBoard() {
        this.board = [];
        for (let row = 0; row < this.boardSize; row++) {
            this.board[row] = [];
            for (let col = 0; col < this.boardSize; col++) {
                do {
                    this.board[row][col] = Math.floor(Math.random() * this.blockTypes.length);
                } while (this.hasInitialMatch(row, col));
            }
        }
    }
    
    hasInitialMatch(row, col) {
        const type = this.board[row][col];
        
        // 检查水平匹配
        if (col >= 2 && 
            this.board[row][col-1] === type && 
            this.board[row][col-2] === type) {
            return true;
        }
        
        // 检查垂直匹配
        if (row >= 2 && 
            this.board[row-1][col] === type && 
            this.board[row-2][col] === type) {
            return true;
        }
        
        return false;
    }
    
    renderBoard() {
        const gameBoard = document.getElementById('gameBoard');
        gameBoard.innerHTML = '';
        
        for (let row = 0; row < this.boardSize; row++) {
            for (let col = 0; col < this.boardSize; col++) {
                const cell = document.createElement('div');
                cell.className = 'game-cell';
                cell.dataset.row = row;
                cell.dataset.col = col;
                cell.dataset.type = this.board[row][col];
                cell.textContent = this.blockTypes[this.board[row][col]];
                
                cell.addEventListener('click', () => this.handleCellClick(row, col));
                gameBoard.appendChild(cell);
            }
        }
    }
    
    handleCellClick(row, col) {
        if (!this.gameRunning || this.isPaused || this.moves <= 0) return;
        
        const cell = this.getCellElement(row, col);
        
        // 如果有激活的道具
        if (this.activePowerUp) {
            this.usePowerUp(row, col);
            return;
        }
        
        // 如果已经选中了一个方块
        if (this.selectedCell) {
            const [selectedRow, selectedCol] = this.selectedCell;
            
            // 如果点击同一个方块，取消选择
            if (selectedRow === row && selectedCol === col) {
                this.clearSelection();
                return;
            }
            
            // 检查是否相邻
            if (this.isAdjacent(selectedRow, selectedCol, row, col)) {
                this.swapBlocks(selectedRow, selectedCol, row, col);
                this.clearSelection();
            } else {
                // 选择新的方块
                this.clearSelection();
                this.selectCell(row, col);
            }
        } else {
            // 选择第一个方块
            this.selectCell(row, col);
        }
    }
    
    selectCell(row, col) {
        this.selectedCell = [row, col];
        const cell = this.getCellElement(row, col);
        cell.classList.add('selected');
        this.playSound('select');
    }
    
    clearSelection() {
        if (this.selectedCell) {
            const [row, col] = this.selectedCell;
            const cell = this.getCellElement(row, col);
            cell.classList.remove('selected');
            this.selectedCell = null;
        }
    }
    
    isAdjacent(row1, col1, row2, col2) {
        const rowDiff = Math.abs(row1 - row2);
        const colDiff = Math.abs(col1 - col2);
        return (rowDiff === 1 && colDiff === 0) || (rowDiff === 0 && colDiff === 1);
    }
    
    swapBlocks(row1, col1, row2, col2) {
        // 交换方块
        const temp = this.board[row1][col1];
        this.board[row1][col1] = this.board[row2][col2];
        this.board[row2][col2] = temp;
        
        // 检查是否有匹配
        const matches = this.findAllMatches();
        if (matches.length > 0) {
            this.moves--;
            this.updateUI();
            this.animateSwap(row1, col1, row2, col2, () => {
                this.processMatches();
            });
        } else {
            // 如果没有匹配，换回来
            this.board[row1][col1] = this.board[row2][col2];
            this.board[row2][col2] = temp;
            this.showHint("无效的移动！");
            this.shakeBoard();
        }
    }
    
    animateSwap(row1, col1, row2, col2, callback) {
        const cell1 = this.getCellElement(row1, col1);
        const cell2 = this.getCellElement(row2, col2);
        
        cell1.style.transition = 'transform 0.3s ease';
        cell2.style.transition = 'transform 0.3s ease';
        
        const deltaRow = (row2 - row1) * 50;
        const deltaCol = (col2 - col1) * 50;
        
        cell1.style.transform = `translate(${deltaCol}px, ${deltaRow}px)`;
        cell2.style.transform = `translate(${-deltaCol}px, ${-deltaRow}px)`;
        
        setTimeout(() => {
            this.renderBoard();
            if (callback) callback();
        }, 300);
    }
    
    findAllMatches() {
        const matches = [];
        const visited = new Set();
        
        // 查找水平匹配
        for (let row = 0; row < this.boardSize; row++) {
            let count = 1;
            let currentType = this.board[row][0];
            
            for (let col = 1; col < this.boardSize; col++) {
                if (this.board[row][col] === currentType) {
                    count++;
                } else {
                    if (count >= 3) {
                        for (let i = col - count; i < col; i++) {
                            matches.push([row, i]);
                        }
                    }
                    count = 1;
                    currentType = this.board[row][col];
                }
            }
            
            if (count >= 3) {
                for (let i = this.boardSize - count; i < this.boardSize; i++) {
                    matches.push([row, i]);
                }
            }
        }
        
        // 查找垂直匹配
        for (let col = 0; col < this.boardSize; col++) {
            let count = 1;
            let currentType = this.board[0][col];
            
            for (let row = 1; row < this.boardSize; row++) {
                if (this.board[row][col] === currentType) {
                    count++;
                } else {
                    if (count >= 3) {
                        for (let i = row - count; i < row; i++) {
                            matches.push([i, col]);
                        }
                    }
                    count = 1;
                    currentType = this.board[row][col];
                }
            }
            
            if (count >= 3) {
                for (let i = this.boardSize - count; i < this.boardSize; i++) {
                    matches.push([i, col]);
                }
            }
        }
        
        return matches;
    }
    
    processMatches() {
        const matches = this.findAllMatches();
        
        if (matches.length === 0) {
            this.checkGameEnd();
            return;
        }
        
        this.highlightMatches(matches);
        
        setTimeout(() => {
            this.removeMatches(matches);
            this.applyGravity();
            
            setTimeout(() => {
                this.fillEmptySpaces();
                setTimeout(() => {
                    this.processMatches(); // 递归处理新的匹配
                }, 300);
            }, 300);
        }, 500);
    }
    
    highlightMatches(matches) {
        matches.forEach(([row, col]) => {
            const cell = this.getCellElement(row, col);
            cell.classList.add('matching');
        });
        
        this.playSound('match');
    }
    
    removeMatches(matches) {
        const points = matches.length * 10 * this.level;
        this.score += points;
        this.showScore(points);
        
        // 创建粒子效果
        matches.forEach(([row, col]) => {
            const cell = this.getCellElement(row, col);
            this.createParticles(cell);
            this.board[row][col] = -1; // 标记为空
        });
        
        this.updateUI();
    }
    
    applyGravity() {
        for (let col = 0; col < this.boardSize; col++) {
            let writeIndex = this.boardSize - 1;
            
            for (let row = this.boardSize - 1; row >= 0; row--) {
                if (this.board[row][col] !== -1) {
                    if (writeIndex !== row) {
                        this.board[writeIndex][col] = this.board[row][col];
                        this.board[row][col] = -1;
                    }
                    writeIndex--;
                }
            }
        }
        
        this.renderBoard();
    }
    
    fillEmptySpaces() {
        for (let col = 0; col < this.boardSize; col++) {
            for (let row = 0; row < this.boardSize; row++) {
                if (this.board[row][col] === -1) {
                    this.board[row][col] = Math.floor(Math.random() * this.blockTypes.length);
                    
                    const cell = this.getCellElement(row, col);
                    cell.classList.add('falling');
                }
            }
        }
        
        this.renderBoard();
        
        // 移除动画类
        setTimeout(() => {
            document.querySelectorAll('.falling').forEach(cell => {
                cell.classList.remove('falling');
            });
        }, 500);
    }
    
    usePowerUp(row, col) {
        switch (this.activePowerUp) {
            case 'bomb':
                this.useBomb(row, col);
                break;
            case 'rainbow':
                this.useRainbow(row, col);
                break;
            case 'shuffle':
                this.useShuffle();
                break;
        }
        
        this.activePowerUp = null;
        this.updatePowerUpButtons();
    }
    
    useBomb(row, col) {
        const targets = [];
        
        // 添加周围8个位置的方块
        for (let r = row - 1; r <= row + 1; r++) {
            for (let c = col - 1; c <= col + 1; c++) {
                if (r >= 0 && r < this.boardSize && c >= 0 && c < this.boardSize) {
                    targets.push([r, c]);
                }
            }
        }
        
        this.removeMatches(targets);
        this.applyGravity();
        
        setTimeout(() => {
            this.fillEmptySpaces();
            setTimeout(() => {
                this.processMatches();
            }, 300);
        }, 300);
        
        this.playSound('bomb');
    }
    
    useRainbow(row, col) {
        const targetType = this.board[row][col];
        const targets = [];
        
        // 找到所有相同类型的方块
        for (let r = 0; r < this.boardSize; r++) {
            for (let c = 0; c < this.boardSize; c++) {
                if (this.board[r][c] === targetType) {
                    targets.push([r, c]);
                }
            }
        }
        
        this.removeMatches(targets);
        this.applyGravity();
        
        setTimeout(() => {
            this.fillEmptySpaces();
            setTimeout(() => {
                this.processMatches();
            }, 300);
        }, 300);
        
        this.playSound('rainbow');
    }
    
    useShuffle() {
        // 重新排列棋盘
        const flatBoard = [];
        for (let row = 0; row < this.boardSize; row++) {
            for (let col = 0; col < this.boardSize; col++) {
                flatBoard.push(this.board[row][col]);
            }
        }
        
        // 洗牌
        for (let i = flatBoard.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [flatBoard[i], flatBoard[j]] = [flatBoard[j], flatBoard[i]];
        }
        
        // 重新填充棋盘
        let index = 0;
        for (let row = 0; row < this.boardSize; row++) {
            for (let col = 0; col < this.boardSize; col++) {
                this.board[row][col] = flatBoard[index++];
            }
        }
        
        this.renderBoard();
        this.playSound('shuffle');
    }
    
    checkGameEnd() {
        if (this.score >= this.target) {
            this.levelComplete();
        } else if (this.moves <= 0) {
            this.gameOver();
        }
    }
    
    levelComplete() {
        this.gameRunning = false;
        this.playSound('levelComplete');
        this.showOverlay('关卡完成！', `恭喜！你获得了 ${this.score} 分`, '下一关', () => {
            this.nextLevel();
        });
    }
    
    gameOver() {
        this.gameRunning = false;
        this.playSound('gameOver');
        this.showOverlay('游戏结束', `最终得分：${this.score}`, '重新开始', () => {
            this.restartGame();
        });
    }
    
    nextLevel() {
        this.level++;
        this.moves = Math.max(25, 30 - this.level);
        this.target = this.target + (this.level * 500);
        this.score = 0;
        
        // 增加道具
        this.powerUps.bomb = Math.min(5, this.powerUps.bomb + 1);
        this.powerUps.rainbow = Math.min(3, this.powerUps.rainbow + 1);
        this.powerUps.shuffle = Math.min(2, this.powerUps.shuffle + 1);
        
        this.gameRunning = true;
        this.createBoard();
        this.renderBoard();
        this.updateUI();
        this.hideOverlay();
        
        this.showHint(`第 ${this.level} 关开始！目标：${this.target} 分`);
    }
    
    restartGame() {
        this.score = 0;
        this.level = 1;
        this.moves = 30;
        this.target = 1000;
        this.gameRunning = true;
        
        this.powerUps = {
            bomb: 3,
            rainbow: 2,
            shuffle: 1
        };
        
        this.createBoard();
        this.renderBoard();
        this.updateUI();
        this.hideOverlay();
        
        this.showHint("游戏重新开始！");
    }
    
    pauseGame() {
        this.isPaused = !this.isPaused;
        const pauseBtn = document.getElementById('pauseBtn');
        pauseBtn.textContent = this.isPaused ? '▶️ 继续' : '⏸️ 暂停';
        
        if (this.isPaused) {
            this.showOverlay('游戏暂停', '点击继续按钮恢复游戏', '继续', () => {
                this.pauseGame();
            });
        } else {
            this.hideOverlay();
        }
    }
    
    toggleSound() {
        this.soundEnabled = !this.soundEnabled;
        const soundBtn = document.getElementById('soundBtn');
        soundBtn.textContent = this.soundEnabled ? '🔊 音效' : '🔇 静音';
    }
    
    getCellElement(row, col) {
        return document.querySelector(`[data-row="${row}"][data-col="${col}"]`);
    }
    
    updateUI() {
        document.getElementById('score').textContent = this.score;
        document.getElementById('level').textContent = this.level;
        document.getElementById('moves').textContent = this.moves;
        document.getElementById('target').textContent = this.target;
        
        // 更新进度条
        const progress = Math.min(100, (this.score / this.target) * 100);
        document.getElementById('progressBar').style.width = `${progress}%`;
        document.getElementById('progressText').textContent = `${this.score} / ${this.target}`;
        
        this.updatePowerUpButtons();
    }
    
    updatePowerUpButtons() {
        const bombBtn = document.getElementById('bombPowerUp');
        const rainbowBtn = document.getElementById('rainbowPowerUp');
        const shuffleBtn = document.getElementById('shufflePowerUp');
        
        bombBtn.querySelector('.power-count').textContent = this.powerUps.bomb;
        rainbowBtn.querySelector('.power-count').textContent = this.powerUps.rainbow;
        shuffleBtn.querySelector('.power-count').textContent = this.powerUps.shuffle;
        
        bombBtn.disabled = this.powerUps.bomb <= 0;
        rainbowBtn.disabled = this.powerUps.rainbow <= 0;
        shuffleBtn.disabled = this.powerUps.shuffle <= 0;
        
        // 移除激活状态
        document.querySelectorAll('.power-up').forEach(btn => {
            btn.classList.remove('active');
        });
    }
    
    showOverlay(title, message, buttonText, callback) {
        const overlay = document.getElementById('gameOverlay');
        const overlayTitle = document.getElementById('overlayTitle');
        const overlayMessage = document.getElementById('overlayMessage');
        const overlayButton = document.getElementById('overlayButton');
        
        overlayTitle.textContent = title;
        overlayMessage.textContent = message;
        overlayButton.textContent = buttonText;
        
        overlayButton.onclick = callback;
        overlay.classList.add('show');
    }
    
    hideOverlay() {
        const overlay = document.getElementById('gameOverlay');
        overlay.classList.remove('show');
    }
    
    showHint(text) {
        const hintText = document.getElementById('hintText');
        hintText.textContent = text;
        hintText.parentElement.classList.add('bounce');
        
        setTimeout(() => {
            hintText.parentElement.classList.remove('bounce');
        }, 600);
    }
    
    showScore(points) {
        // 创建飞出的分数显示
        const scoreDisplay = document.createElement('div');
        scoreDisplay.textContent = `+${points}`;
        scoreDisplay.style.position = 'fixed';
        scoreDisplay.style.left = '50%';
        scoreDisplay.style.top = '20%';
        scoreDisplay.style.transform = 'translateX(-50%)';
        scoreDisplay.style.color = '#ffd700';
        scoreDisplay.style.fontSize = '2rem';
        scoreDisplay.style.fontWeight = 'bold';
        scoreDisplay.style.pointerEvents = 'none';
        scoreDisplay.style.zIndex = '1001';
        scoreDisplay.style.animation = 'score-fly 1s ease-out forwards';
        
        document.body.appendChild(scoreDisplay);
        
        setTimeout(() => {
            document.body.removeChild(scoreDisplay);
        }, 1000);
    }
    
    createParticles(element) {
        const rect = element.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        
        for (let i = 0; i < 6; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.left = centerX + 'px';
            particle.style.top = centerY + 'px';
            
            const angle = (i / 6) * Math.PI * 2;
            const distance = 50 + Math.random() * 50;
            const endX = centerX + Math.cos(angle) * distance;
            const endY = centerY + Math.sin(angle) * distance;
            
            particle.style.setProperty('--end-x', endX + 'px');
            particle.style.setProperty('--end-y', endY + 'px');
            
            document.getElementById('particleContainer').appendChild(particle);
            
            setTimeout(() => {
                particle.remove();
            }, 1000);
        }
    }
    
    shakeBoard() {
        const board = document.getElementById('gameBoard');
        board.classList.add('shake');
        setTimeout(() => {
            board.classList.remove('shake');
        }, 500);
    }
    
    playSound(type) {
        if (!this.soundEnabled) return;
        
        // 创建简单的音效（使用Web Audio API）
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        const frequencies = {
            select: 440,
            match: 660,
            bomb: 220,
            rainbow: 880,
            shuffle: 550,
            levelComplete: 1100,
            gameOver: 165
        };
        
        oscillator.frequency.setValueAtTime(frequencies[type] || 440, audioContext.currentTime);
        oscillator.type = 'sine';
        
        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.3);
    }
    
    bindEvents() {
        // 道具按钮事件
        document.getElementById('bombPowerUp').addEventListener('click', () => {
            if (this.powerUps.bomb > 0) {
                this.activePowerUp = this.activePowerUp === 'bomb' ? null : 'bomb';
                this.powerUps.bomb--;
                this.updatePowerUpButtons();
                this.showHint(this.activePowerUp ? '选择一个位置使用炸弹' : '道具已取消');
            }
        });
        
        document.getElementById('rainbowPowerUp').addEventListener('click', () => {
            if (this.powerUps.rainbow > 0) {
                this.activePowerUp = this.activePowerUp === 'rainbow' ? null : 'rainbow';
                this.powerUps.rainbow--;
                this.updatePowerUpButtons();
                this.showHint(this.activePowerUp ? '选择一个方块清除同色方块' : '道具已取消');
            }
        });
        
        document.getElementById('shufflePowerUp').addEventListener('click', () => {
            if (this.powerUps.shuffle > 0) {
                this.powerUps.shuffle--;
                this.useShuffle();
                this.updateUI();
                this.showHint('棋盘已重新排列！');
            }
        });
        
        // 控制按钮事件
        document.getElementById('pauseBtn').addEventListener('click', () => {
            this.pauseGame();
        });
        
        document.getElementById('restartBtn').addEventListener('click', () => {
            if (confirm('确定要重新开始游戏吗？')) {
                this.restartGame();
            }
        });
        
        document.getElementById('soundBtn').addEventListener('click', () => {
            this.toggleSound();
        });
        
        // 键盘快捷键
        document.addEventListener('keydown', (e) => {
            switch (e.key) {
                case ' ':
                    e.preventDefault();
                    this.pauseGame();
                    break;
                case 'r':
                case 'R':
                    if (e.ctrlKey) {
                        e.preventDefault();
                        this.restartGame();
                    }
                    break;
                case 'm':
                case 'M':
                    this.toggleSound();
                    break;
            }
        });
    }
}

// 添加CSS动画
const style = document.createElement('style');
style.textContent = `
    @keyframes score-fly {
        0% {
            transform: translateX(-50%) translateY(0) scale(1);
            opacity: 1;
        }
        100% {
            transform: translateX(-50%) translateY(-50px) scale(1.5);
            opacity: 0;
        }
    }
    
    .power-up.active {
        background: rgba(255, 215, 0, 0.3) !important;
        border-color: #ffd700 !important;
    }
    
    .particle {
        transform: translate(var(--end-x), var(--end-y));
    }
`;
document.head.appendChild(style);

// 游戏初始化
let game;
document.addEventListener('DOMContentLoaded', () => {
    game = new MatchThreeGame();
});