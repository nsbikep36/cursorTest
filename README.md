# 2048 在线版

一个零依赖、可直接在浏览器中游玩的 2048 小游戏（支持键盘与触控滑动）。

## 本地运行

- 方式一：直接双击打开 `2048/index.html`（推荐 Chrome/Edge/Firefox 新版）
- 方式二：本地静态服务器（推荐，支持模块与跨域更一致）

```bash
# 使用 Python 3 自带 http.server
cd 2048
python3 -m http.server 5173
# 然后访问 http://localhost:5173
```

若没有 Python 也可以使用任意静态服务器（如 `busybox httpd`、`npx serve` 等）。

## 操作说明
- 方向键或 `WASD`：控制合并方向
- 触控设备：在棋盘上滑动
- 点击“新开一局”：重置游戏

## 功能
- 4x4 棋盘、2048 合并规则
- 分数与本地最佳分记录（`localStorage`）
- 键盘与触控滑动支持
- 赢得 2048 提示、继续游戏/再来一局
