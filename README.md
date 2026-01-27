# Claude Companion

A pixel art notification buddy that lives in the corner of your screen and reacts to Claude's state.

## Features

- **Pixel art character** with expressive animations
- **States**: sleeping, idle, thinking, working, attention, success, error, listening
- **Mouse interactions**: hovers and clicks trigger responses
- **Sound effects**: custom synthesized chiptune-style sounds
- **MCP integration**: Claude can control the companion naturally

## Quick Start

```bash
./setup.sh
```

This will:
1. Build the macOS app
2. Install the MCP server
3. Show you how to configure Claude Code

## Manual Setup

### 1. Build the App

```bash
cd app
swift build -c release
```

### 2. Install MCP Server

```bash
cd mcp-server
npm install
npm run build
```

### 3. Configure Claude Code

Add to `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "claude-companion": {
      "command": "node",
      "args": ["/path/to/claude-companion/mcp-server/dist/index.js"]
    }
  }
}
```

### 4. Launch

```bash
# Run the app
swift run --package-path app
# Or after setup.sh, just:
open ClaudeCompanion.app
```

## States & Animations

| State | Trigger | Visual |
|-------|---------|--------|
| Sleeping | Claude not running | Closed eyes, Z's floating |
| Idle | Default awake | Occasional blinking |
| Thinking | Processing | Looking up, dots appear |
| Working | Active task | Focused expression |
| Attention | Needs input | Bouncing, wide eyes |
| Success | Task complete | Happy eyes, sparkles |
| Error | Something wrong | Worried look |
| Listening | Waiting | Attentive expression |

## Mouse Interactions

- **Hover**: Companion looks at you curiously
- **Click**: Happy bounce and sound
- **Double-click**: Wave hello!

## Sounds

All sounds are procedurally generated warm, chiptune-style tones:
- Chime (attention)
- Success (celebration)
- Wake up (gentle rise)
- Click response (short blip)
- Hello (friendly wave)

## Architecture

```
claude-companion/
├── app/                    # Swift macOS app
│   └── ClaudeCompanion/
│       ├── ClaudeCompanionApp.swift  # Main app, window setup
│       ├── CompanionView.swift       # Main UI view
│       ├── PixelCharacter.swift      # Pixel art renderer
│       ├── AnimationController.swift # State machine
│       ├── SoundManager.swift        # Sound generation
│       ├── StateManager.swift        # HTTP server for MCP
│       └── CompanionState.swift      # State definitions
├── mcp-server/             # MCP server for Claude
│   └── src/index.ts        # MCP tool definitions
└── setup.sh                # Setup script
```

## HTTP API (Internal)

The app runs a local HTTP server on port 52532 for MCP communication:

- `POST /state` - Set companion state
- `POST /notify` - Trigger attention
- `POST /heartbeat` - Keep awake
- `GET /status` - Get current state
- `POST /sleep` - Go to sleep
