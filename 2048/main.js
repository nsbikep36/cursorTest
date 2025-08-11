class Game2048 {
  constructor(boardSize = 4) {
    this.boardSize = boardSize;
    this.score = 0;
    this.best = Number(localStorage.getItem('bestScore2048') || '0');
    this.hasReached2048 = false;
    this.keepPlayingAfterWin = false;

    this.grid = this.createEmptyGrid();
  }

  createEmptyGrid() {
    return Array.from({ length: this.boardSize }, () => Array(this.boardSize).fill(0));
  }

  reset() {
    this.score = 0;
    this.hasReached2048 = false;
    this.keepPlayingAfterWin = false;
    this.grid = this.createEmptyGrid();
    this.addRandomTile();
    this.addRandomTile();
  }

  getEmptyCells() {
    const empties = [];
    for (let r = 0; r < this.boardSize; r++) {
      for (let c = 0; c < this.boardSize; c++) {
        if (this.grid[r][c] === 0) empties.push([r, c]);
      }
    }
    return empties;
  }

  addRandomTile() {
    const empties = this.getEmptyCells();
    if (empties.length === 0) return false;
    const [r, c] = empties[Math.floor(Math.random() * empties.length)];
    // 90% for 2, 10% for 4
    this.grid[r][c] = Math.random() < 0.9 ? 2 : 4;
    return true;
  }

  isInside(row, col) {
    return row >= 0 && row < this.boardSize && col >= 0 && col < this.boardSize;
  }

  cloneGrid(grid = this.grid) {
    return grid.map(row => row.slice());
  }

  hasAnyMoves() {
    if (this.getEmptyCells().length > 0) return true;
    // Check merges available
    for (let r = 0; r < this.boardSize; r++) {
      for (let c = 0; c < this.boardSize; c++) {
        const v = this.grid[r][c];
        if (v === 0) return true;
        const neighbors = [
          [r + 1, c],
          [r, c + 1]
        ];
        for (const [nr, nc] of neighbors) {
          if (this.isInside(nr, nc) && this.grid[nr][nc] === v) return true;
        }
      }
    }
    return false;
  }

  move(direction) {
    // Returns { moved: boolean, scoreGained: number, mergedPositions: Set<string>, newGrid }
    let rotated = false;
    let flipped = false;

    let working = this.cloneGrid();

    // Normalize movement to left by rotating / flipping
    if (direction === 'up') {
      working = rotateLeft(working);
      rotated = true;
    } else if (direction === 'down') {
      working = rotateRight(working);
      rotated = true;
    } else if (direction === 'right') {
      working = flipRows(working);
      flipped = true;
    } else if (direction !== 'left') {
      return { moved: false, scoreGained: 0, mergedPositions: new Set(), newGrid: this.cloneGrid() };
    }

    let moved = false;
    let scoreGained = 0;
    const mergedPositions = new Set();

    for (let r = 0; r < this.boardSize; r++) {
      const row = working[r].filter(v => v !== 0);
      const compressed = [];
      for (let i = 0; i < row.length; i++) {
        if (i < row.length - 1 && row[i] === row[i + 1]) {
          const mergedValue = row[i] * 2;
          compressed.push(mergedValue);
          scoreGained += mergedValue;
          mergedPositions.add(`${r}:${compressed.length - 1}`);
          i++; // skip next
        } else {
          compressed.push(row[i]);
        }
      }
      while (compressed.length < this.boardSize) compressed.push(0);
      if (!arraysEqual(working[r], compressed)) moved = true;
      working[r] = compressed;
    }

    // Undo normalization
    if (flipped) working = flipRows(working);
    if (rotated && direction === 'up') working = rotateRight(working);
    if (rotated && direction === 'down') working = rotateLeft(working);

    if (!moved) {
      return { moved: false, scoreGained: 0, mergedPositions: new Set(), newGrid: this.cloneGrid() };
    }

    // Apply result
    this.grid = working;
    this.score += scoreGained;
    if (this.score > this.best) {
      this.best = this.score;
      localStorage.setItem('bestScore2048', String(this.best));
    }

    return { moved: true, scoreGained, mergedPositions, newGrid: this.cloneGrid() };
  }
}

// Helpers
function rotateLeft(grid) {
  const n = grid.length;
  const out = Array.from({ length: n }, () => Array(n).fill(0));
  for (let r = 0; r < n; r++) {
    for (let c = 0; c < n; c++) {
      out[n - c - 1][r] = grid[r][c];
    }
  }
  return out;
}
function rotateRight(grid) {
  const n = grid.length;
  const out = Array.from({ length: n }, () => Array(n).fill(0));
  for (let r = 0; r < n; r++) {
    for (let c = 0; c < n; c++) {
      out[c][n - r - 1] = grid[r][c];
    }
  }
  return out;
}
function flipRows(grid) {
  return grid.map(row => row.slice().reverse());
}
function arraysEqual(a, b) {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

// UI Controller
class GameUI {
  constructor(root) {
    this.root = root;
    this.boardEl = document.getElementById('board');
    this.scoreEl = document.getElementById('score');
    this.bestEl = document.getElementById('best');
    this.overlayEl = document.getElementById('overlay');
    this.overlayMsgEl = document.getElementById('overlay-message');
    this.keepGoingBtn = document.getElementById('keep-going');
    this.tryAgainBtn = document.getElementById('try-again');
    this.newGameBtn = document.getElementById('new-game');

    this.game = new Game2048(4);

    this.touchStart = null;

    this.initBoard();
    this.bindEvents();
    this.startNewGame();
  }

  initBoard() {
    // Create 16 background cells + a tiles overlay container
    this.boardEl.innerHTML = '';

    // Background cells
    for (let i = 0; i < 16; i++) {
      const cell = document.createElement('div');
      cell.className = 'cell';
      this.boardEl.appendChild(cell);
    }

    // Tiles overlay
    this.tilesLayer = document.createElement('div');
    this.tilesLayer.className = 'tiles';
    this.boardEl.appendChild(this.tilesLayer);
  }

  bindEvents() {
    // Buttons
    this.newGameBtn.addEventListener('click', () => this.startNewGame());
    this.tryAgainBtn.addEventListener('click', () => this.startNewGame());
    this.keepGoingBtn.addEventListener('click', () => {
      this.game.keepPlayingAfterWin = true;
      this.hideOverlay();
    });

    // Keyboard
    window.addEventListener('keydown', (e) => {
      const key = e.key.toLowerCase();
      let dir = null;
      if (key === 'arrowup' || key === 'w') dir = 'up';
      else if (key === 'arrowdown' || key === 's') dir = 'down';
      else if (key === 'arrowleft' || key === 'a') dir = 'left';
      else if (key === 'arrowright' || key === 'd') dir = 'right';
      if (!dir) return;
      e.preventDefault();
      this.handleMove(dir);
    });

    // Touch
    this.boardEl.addEventListener('touchstart', (e) => {
      if (!e.touches || e.touches.length === 0) return;
      const t = e.touches[0];
      this.touchStart = { x: t.clientX, y: t.clientY };
    }, { passive: true });

    this.boardEl.addEventListener('touchmove', (e) => {
      // Prevent scroll when swiping on board
      if (e.cancelable) e.preventDefault();
    }, { passive: false });

    this.boardEl.addEventListener('touchend', (e) => {
      if (!this.touchStart) return;
      const t = e.changedTouches[0];
      const dx = t.clientX - this.touchStart.x;
      const dy = t.clientY - this.touchStart.y;
      const absX = Math.abs(dx);
      const absY = Math.abs(dy);
      const threshold = 24; // minimum swipe distance
      let dir = null;
      if (Math.max(absX, absY) < threshold) {
        this.touchStart = null;
        return;
      }
      if (absX > absY) dir = dx > 0 ? 'right' : 'left';
      else dir = dy > 0 ? 'down' : 'up';
      this.touchStart = null;
      this.handleMove(dir);
    });
  }

  startNewGame() {
    this.game.reset();
    this.updateScores();
    this.hideOverlay();
    this.render(true);
  }

  handleMove(direction) {
    const before = this.game.cloneGrid();
    const result = this.game.move(direction);
    if (!result.moved) return;

    // Add a random tile after a successful move
    this.game.addRandomTile();

    this.updateScores();
    this.render(false, before, result);

    // Check win/lose states
    if (!this.game.hasReached2048 && this.contains2048(this.game.grid)) {
      this.game.hasReached2048 = true;
      if (!this.game.keepPlayingAfterWin) {
        this.showOverlay('你赢了！🎉');
        this.keepGoingBtn.classList.remove('hidden');
      }
    }

    if (!this.game.hasAnyMoves()) {
      this.showOverlay('游戏结束 😵');
      this.keepGoingBtn.classList.add('hidden');
    }
  }

  contains2048(grid) {
    for (const row of grid) {
      for (const v of row) if (v >= 2048) return true;
    }
    return false;
  }

  updateScores() {
    this.scoreEl.textContent = String(this.game.score);
    this.bestEl.textContent = String(this.game.best);
  }

  showOverlay(message) {
    this.overlayMsgEl.textContent = message;
    this.overlayEl.classList.remove('hidden');
  }
  hideOverlay() {
    this.overlayEl.classList.add('hidden');
  }

  render(isReset = false, prevGrid = null, moveResult = null) {
    // Rebuild tiles layer from current grid
    this.tilesLayer.innerHTML = '';

    const grid = this.game.grid;

    for (let r = 0; r < this.game.boardSize; r++) {
      for (let c = 0; c < this.game.boardSize; c++) {
        const val = grid[r][c];
        if (val === 0) continue;
        const tile = document.createElement('div');
        const cls = valueToClass(val);
        tile.className = `tile ${cls}`;
        tile.style.gridRowStart = String(r + 1);
        tile.style.gridColumnStart = String(c + 1);
        tile.textContent = String(val);

        if (isReset) {
          tile.classList.add('tile-new');
        } else if (prevGrid && moveResult) {
          // New tile detection: present in current grid but not in previous at same position
          if (prevGrid[r][c] === 0) {
            tile.classList.add('tile-new');
          }
        }

        this.tilesLayer.appendChild(tile);
      }
    }
  }
}

function valueToClass(v) {
  if (v <= 2048) return `tile-${v}`;
  return 'tile-super';
}

// Bootstrap UI
window.addEventListener('DOMContentLoaded', () => {
  new GameUI(document.body);
});