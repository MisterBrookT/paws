[English](README.md) | 中文

<div align="center">

# 🐾 Paws

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Built for Kaku](https://img.shields.io/badge/Built_for-Kaku-blue)](https://github.com/tw93/kaku) [![Made with Lua & Rust](https://img.shields.io/badge/Made_with-Lua_&_Rust-orange)]() [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/MisterBrookT/paws/pulls) [![GitHub Stars](https://img.shields.io/github/stars/MisterBrookT/paws?style=flat&color=yellow)](https://github.com/MisterBrookT/paws/stargazers)

Agent 工作时尽情玩，需要你时一眼就看到。

AI Agent 工作时玩游戏，状态 HUD 告诉你何时该回来。

</div>

<p align="center"><img src="docs/demo.gif" width="600" alt="Paws demo"></p>

AI 编程 Agent 的终端伴侣。Paws 在 Agent 工作时给你一个沉浸式全屏游戏——游戏里还有一条状态栏，实时显示你的各个 Agent session 哪些在跑、哪些已完成，你想切回去时再切，主动权在你。

专为 vibe coding 中被忽视的那段时间而生：你想守在终端旁，但 Agent 正在思考，你无事可做。

## 工作原理

```
        按下 CMD+G                        某个 session 完成
  ┌──────────────────────┐          ┌──────────────────────────┐
  │  🎮 游戏标签页         │          │   ● 1 running  ✓ 1 done!  │  ← 实时 HUD
  │  (全窗口)             │  CMD+G   │   (完成时会闪烁)          │
  │  ● 2 running          │ ───────> │                           │
  └──────────────────────┘          └──────────────────────────┘
```

随时用 **CMD+G** 切换。游戏里的状态 HUD 显示每个 Agent session 的状态（运行中 / 已完成），**有一个完成时会闪烁**，绝不会错过——也不会在你玩到一半时被突然弹走。

### 快捷键

| 按键 | 功能 |
|------|------|
| **CMD+G** | 首次按下：选择游戏；之后：在 Agent ↔ 游戏间切换 |
| **CMD+SHIFT+P** | 重新打开菜单，换一个游戏 |

> 故意不用 `CMD+SHIFT+G`——Kaku 已把它绑给了 lazygit。

游戏运行在独立的**标签页**中，天然全窗口沉浸——你现有的分屏布局不会被打扰。切换**刻意保持手动**：HUD（配合可选的完成提示音）告诉你该回来了，主动权始终在你手里。

## 设计哲学

一切运行在终端自身的原生扩展层内。**没有外部控制脚本，没有自动切换的"魔法"，不调用 `kaku cli`。**

```
Kiro hook ─ 一行：把本 session 的状态写到 /tmp/paws-sessions/<id>
       │
       ▼
Kaku Lua ─ 只管 CMD+G / CMD+SHIFT+P：用 wezterm.mux 创建/切换标签页，
       │   状态存在 wezterm.GLOBAL 中——全部 in-process
       ▼
游戏标签页 ─ `paws` wrapper 把游戏居中托管在 PTY 里，并读取
            /tmp/paws-sessions/ 渲染实时 session 状态 HUD
```

标签页归终端管，所以标签页控制就该在终端的 Lua 层——而不是从外部伸手进来。Agent 唯一要做的就是把自己的状态写进一个文件；没有任何东西会伸进来移动你。

## 环境要求

- [Kaku 终端](https://github.com/tw93/kaku)（WezTerm 分支）
- [Kiro CLI](https://kiro.dev)（主要支持）或 Claude Code（计划中）
- Rust 工具链（`cargo`），用于构建 `paws` wrapper
- 一款或多款终端游戏 — `brew install vitetris`（俄罗斯方块）和/或 `cargo install --git https://github.com/MisterBrookT/jump-high`

## 安装

### 简单方式 — 让你的 Agent 来装

Paws 自带安装 skill。克隆仓库后直接告诉你的 AI 编程 Agent：

> "用 `paws/skills/paws-install/SKILL.md` 里的 skill 安装 Paws。"

Agent 会把 Lua 合并到你的 Kaku 配置、接好 hooks、装好游戏，然后提示你重载。无需手动编辑。（Kiro 原生读取 `SKILL.md`；Claude Code 也能读。）

### 手动方式

1. 构建：`cargo install --path .`（在 PATH 中生成 `paws`）。
2. 将 [`lua/paws.lua`](lua/paws.lua) 添加到 `~/.config/kaku/kaku.lua`（放在 `return config` 之前）。
3. 将 [`hooks/kiro/paws-signal.sh`](hooks/kiro/paws-signal.sh) 配置为 Kiro 的 `stop` 和 `userPromptSubmit` hooks（绝对路径，注意 `done`/`busy` 参数）。它只是记录每个 session 的状态给 HUD 用，不会移动你：
   ```json
   "hooks": {
     "stop":             [{ "command": "/absolute/path/to/paws-signal.sh done" }],
     "userPromptSubmit": [{ "command": "/absolute/path/to/paws-signal.sh busy" }]
   }
   ```
   （可选：在 `stop` 里加一声完成提示音，如 `afplay /System/Library/Sounds/Glass.aiff`。）
4. 装好游戏后，重载 Kaku（CMD+Shift+R），按 **CMD+G** 即可。

## 路线图

### 已完成
- [x] 原生标签页切换（纯 Lua，`wezterm.mux`，`wezterm.GLOBAL`）
- [x] 游戏选择菜单 `InputSelector`（CMD+G 首次；CMD+SHIFT+P 重选）
- [x] 通过 Agent skill 一键安装
- [x] Rust wrapper：把游戏**居中**托管在 PTY 里
- [x] 实时多 session 状态 HUD（运行中 / 已完成，完成时闪烁）
- [x] [Jump High](https://github.com/MisterBrookT/jump-high) — Jump King 风格终端游戏（ratatui）

### 接下来
1. **更多游戏** — 扩充精选列表，加入更多适合随时打断的游戏。
2. **Claude Code 支持** — 同样的 per-session 状态 hook。
3. **`brew install paws`** — Homebrew formula 一键安装。

## 设计文档

完整设计思路见 [`docs/design.tex`](docs/design.tex)。

## 许可证

MIT
