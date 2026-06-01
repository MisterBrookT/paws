# Paws Multi-Agent Setup

Paws can show the live status of **any** AI coding agent in its HUD — not just Kiro.
Each agent writes session state to `/tmp/paws-sessions/` via a lightweight hook script.

## Quick Install

```bash
# 1. Copy the hook script to a shared location
mkdir -p ~/.paws/hooks
cp hooks/paws-hook.sh ~/.paws/hooks/paws-hook.sh
chmod +x ~/.paws/hooks/paws-hook.sh
```

Then configure your agent(s) below.

---

## Claude Code

Merge the following into `~/.claude/settings.json` (create it if it doesn't exist):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.paws/hooks/paws-hook.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.paws/hooks/paws-hook.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

If you already have hooks in that file, add the Paws entries to the existing
`PreToolUse` and `Stop` arrays.

---

## Codex CLI

Merge the following into `~/.codex/hooks.json` (create it if it doesn't exist):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.paws/hooks/paws-hook.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.paws/hooks/paws-hook.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Or add the equivalent TOML to `~/.codex/config.toml`:

```toml
[[hooks.PreToolUse]]
matcher = ""

[[hooks.PreToolUse.hooks]]
type = "command"
command = "~/.paws/hooks/paws-hook.sh"
timeout = 5

[[hooks.Stop]]

[[hooks.Stop.hooks]]
type = "command"
command = "~/.paws/hooks/paws-hook.sh"
timeout = 5
```

---

## Kiro

Kiro uses a different mechanism (shell hook in `~/.kiro/hooks/paws-pause.sh`).
If you installed Paws via the Kiro skill, this is already set up.

---

## How It Works

1. When the agent starts using a tool (`PreToolUse`), the hook writes
   `busy <PID>` to `/tmp/paws-sessions/<session_id>`.
2. When the agent finishes a turn (`Stop`), it writes `done <PID>`.
3. The Paws HUD reads these files, checks PID liveness, and shows a
   running/waiting count with an animated indicator.

The hook is ~30 lines of bash, adds <5ms per tool call, and uses atomic
writes (temp + rename) to prevent flicker.

---

## Verify

After setup, run your agent on any task, then check:

```bash
ls /tmp/paws-sessions/
# Should show one or more session files

cat /tmp/paws-sessions/*
# Should show "busy <pid>" or "done <pid>"
```

Open Paws (`CMD+G` in Kiro/Kaku) and the HUD should reflect the session count.
