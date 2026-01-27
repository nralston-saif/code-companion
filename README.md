# Claude Companion

A delightful pixel art desktop pet that lives in the corner of your screen and reacts to Claude Code's activity. Think Clippy meets Tamagotchi, but actually helpful.

![Claude Companion](https://img.shields.io/badge/macOS-14.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![MCP](https://img.shields.io/badge/MCP-Compatible-green)

## Features

### Lifelike Animations
- **Breathing animation** - Subtle idle breathing when resting
- **Random idle behaviors** - Yawning, stretching, looking around, scratching head
- **Eye tracking** - Eyes follow your cursor or look toward screen center
- **Expressive states** - Different expressions for thinking, working, success, error, and more

### Interactive Pet
- **Click reactions** - Single click for a happy response
- **Pet/poke system** - Click repeatedly to pet (3x), make giggle (5x), or dizzy (8x)
- **Double-click wave** - Wave hello!
- **Drag reactions** - Wiggles when dragged, settles when dropped
- **Mood system** - Hidden happiness meter affects appearance (sparkly eyes when happy, droopy when sad)

### Visual Customization
- **5 color skins** - Classic, Ocean, Forest, Sunset, Lavender, Midnight
- **Speech/thought bubbles** - Display emoji or text messages
- **Particle effects** - Confetti, sparkles, hearts, rain clouds
- **Status tooltip** - See what Claude is working on when hovering

### System Integration
- **Menu bar icon** - Quick access to controls and settings
- **Notification queue** - Badge count for stacked notifications
- **Launch at login** - Start automatically with your Mac
- **Configurable sounds** - Notification and ambient sound toggles

### MCP Tools for Claude
Claude Code can control the companion using these tools:
- `companion_thinking` - Show thinking state with status message
- `companion_working` - Show working state with status message
- `companion_attention` - Get user's attention (bounces and sounds)
- `companion_success` - Celebrate task completion
- `companion_error` - Show concern for errors
- `companion_idle` - Return to default state
- `companion_listening` - Show listening state
- `companion_wave` - Friendly wave animation

## Quick Start

### Prerequisites
- macOS 14.0 or later
- [Claude Code](https://claude.ai/claude-code) CLI installed
- Node.js 18+ (for MCP server)

### Installation

```bash
# Clone the repository
git clone https://github.com/nralston-saif/claude-companion.git
cd claude-companion

# Run setup script
./setup.sh
```

This will:
1. Build the macOS app
2. Install and build the MCP server
3. Show configuration instructions

### Configure Claude Code

Add to your Claude Code MCP settings (`~/.claude.json` or via Claude Code settings):

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

Replace `/path/to/claude-companion` with your actual installation path.

### Launch

```bash
# Option 1: Run from terminal
cd claude-companion/app
swift run

# Option 2: Use the built app
open ClaudeCompanion.app

# Option 3: Add to Applications and launch from there
cp -r ClaudeCompanion.app /Applications/
```

## Manual Setup

### 1. Build the Swift App

```bash
cd app
swift build -c release

# Create app bundle
mkdir -p ../ClaudeCompanion.app/Contents/MacOS
cp .build/release/ClaudeCompanion ../ClaudeCompanion.app/Contents/MacOS/
```

### 2. Build the MCP Server

```bash
cd mcp-server
npm install
npm run build
```

### 3. Run

```bash
# Terminal
swift run --package-path app

# Or use the app bundle
open ClaudeCompanion.app
```

## Usage

### Mouse Interactions

| Action | Result |
|--------|--------|
| Hover | Companion looks at you curiously |
| Click | Happy bounce |
| Click 3x quickly | Gets petted, shows blush |
| Click 5x quickly | Giggles with hearts |
| Click 8x quickly | Gets dizzy with spiral eyes |
| Double-click | Waves hello |
| Drag | Wiggles while being moved |
| Right-click | Opens settings menu |

### States

| State | Trigger | Visual |
|-------|---------|--------|
| Sleeping | No Claude activity for 30s | Closed eyes, floating Z's |
| Idle | Default awake state | Blinking, breathing, random animations |
| Thinking | Claude processing | Looking up, thinking dots |
| Working | Active task | Focused expression |
| Attention | Needs user input | Bouncing, wide eyes, exclamation mark |
| Success | Task completed | Happy eyes, sparkles |
| Error | Something went wrong | Worried expression |
| Listening | Waiting for input | Attentive expression |

### Settings

Access settings via right-click menu or menu bar icon:

- **Notifications** - Toggle alerts for permissions, completion, idle, errors
- **Sounds** - Enable/disable notification and ambient sounds
- **Eye Tracking** - Follow cursor, screen center, or disabled
- **Skin** - Choose from 6 color themes
- **Launch at Login** - Start with macOS
- **Show Menu Bar Icon** - Toggle menu bar presence

## Architecture

```
claude-companion/
├── app/                          # Swift macOS app
│   └── ClaudeCompanion/
│       ├── ClaudeCompanionApp.swift    # Main app entry
│       ├── CompanionView.swift         # Main UI with interactions
│       ├── PixelCharacter.swift        # Canvas-based pixel renderer
│       ├── AnimationController.swift   # Animation state machine
│       ├── StateManager.swift          # HTTP server for MCP
│       ├── CompanionState.swift        # State definitions
│       ├── SettingsManager.swift       # User preferences
│       ├── SoundManager.swift          # System sounds
│       ├── MenuBarController.swift     # Menu bar integration
│       ├── SkinManager.swift           # Color themes
│       ├── PetStats.swift              # Happiness/mood tracking
│       ├── NotificationQueue.swift     # Notification management
│       ├── BubbleOverlay.swift         # Speech/thought bubbles
│       └── ParticleSystem.swift        # Visual effects
├── mcp-server/                   # MCP server
│   └── src/index.ts              # Tool definitions
├── ClaudeCompanion.app/          # Built app bundle
├── setup.sh                      # Installation script
└── README.md
```

## HTTP API

The app runs a local server on port `52532` for MCP communication:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/state` | POST | Set companion state (`{state, duration?}`) |
| `/status` | GET | Get current state |
| `/status` | POST | Set status message (`{message}`) |
| `/bubble` | POST | Show bubble (`{text?, emoji?, type?, duration?}`) |
| `/particles` | POST | Show particles (`{effect, duration?}`) |
| `/notification` | POST | Queue notification (`{message, emoji?, priority?}`) |
| `/heartbeat` | POST | Keep companion awake |
| `/sleep` | POST | Put companion to sleep |

## Troubleshooting

### Companion not responding to Claude
1. Check that MCP server is configured in Claude Code settings
2. Verify the path in your config is correct
3. Restart Claude Code after config changes

### App won't launch
1. Check macOS security settings (System Preferences > Privacy & Security)
2. Try running from terminal to see error messages: `swift run --package-path app`

### Two companions appearing
1. Check for multiple running instances: `pgrep -l ClaudeCompanion`
2. Kill all instances: `pkill ClaudeCompanion`
3. Restart single instance

## Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest new animations or features
- Add new skins
- Improve MCP integration

## License

MIT License - feel free to use and modify!

---

Made with love for the Claude Code community
