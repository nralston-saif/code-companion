#!/bin/bash

set -e

echo "🤖 Setting up Code Companion..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Build the Swift app
echo -e "${BLUE}Step 1: Building the macOS app...${NC}"
cd app
swift build -c release
echo -e "${GREEN}✓ App built successfully${NC}"
echo ""

# Step 2: Create the app bundle
echo -e "${BLUE}Step 2: Creating app bundle...${NC}"
APP_BUNDLE="$SCRIPT_DIR/CodeCompanion.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp .build/release/CodeCompanion "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp CodeCompanion/Info.plist "$APP_BUNDLE/Contents/"

echo -e "${GREEN}✓ App bundle created at $APP_BUNDLE${NC}"
echo ""

# Step 3: Install MCP server dependencies
echo -e "${BLUE}Step 3: Installing MCP server dependencies...${NC}"
cd "$SCRIPT_DIR/mcp-server"
npm install
npm run build
echo -e "${GREEN}✓ MCP server ready${NC}"
echo ""

# Step 4: Configure MCP server
echo -e "${BLUE}Step 4: Configuring MCP server...${NC}"
CLAUDE_CONFIG="$HOME/.claude.json"

if [ -f "$CLAUDE_CONFIG" ]; then
  # Check if jq is available
  if command -v jq &> /dev/null; then
    # Check if code-companion is already configured
    if jq -e '.mcpServers["code-companion"]' "$CLAUDE_CONFIG" > /dev/null 2>&1; then
      # Update existing entry
      jq --arg path "$SCRIPT_DIR/mcp-server/dist/index.js" \
        '.mcpServers["code-companion"] = {"command": "node", "args": [$path]}' \
        "$CLAUDE_CONFIG" > "$CLAUDE_CONFIG.tmp" && mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"
      echo -e "${GREEN}✓ Updated existing MCP configuration${NC}"
    else
      # Add new entry
      jq --arg path "$SCRIPT_DIR/mcp-server/dist/index.js" \
        '.mcpServers["code-companion"] = {"command": "node", "args": [$path]}' \
        "$CLAUDE_CONFIG" > "$CLAUDE_CONFIG.tmp" && mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"
      echo -e "${GREEN}✓ Added MCP configuration to ~/.claude.json${NC}"
    fi
  else
    echo -e "${BLUE}jq not found. Please add manually to ~/.claude.json:${NC}"
    echo ""
    echo '  "mcpServers": {'
    echo '    "code-companion": {'
    echo "      \"command\": \"node\","
    echo "      \"args\": [\"$SCRIPT_DIR/mcp-server/dist/index.js\"]"
    echo '    }'
    echo '  }'
  fi
else
  # Create new config file
  echo "{\"mcpServers\":{\"code-companion\":{\"command\":\"node\",\"args\":[\"$SCRIPT_DIR/mcp-server/dist/index.js\"]}}}" > "$CLAUDE_CONFIG"
  echo -e "${GREEN}✓ Created ~/.claude.json with MCP configuration${NC}"
fi
echo ""

# Step 5: Configure hooks
echo -e "${BLUE}Step 5: Configuring Claude Code hooks...${NC}"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
COMPANION_BIN="$SCRIPT_DIR/bin/companion"

# Ensure .claude directory exists
mkdir -p "$HOME/.claude"

if command -v jq &> /dev/null; then
  if [ -f "$CLAUDE_SETTINGS" ]; then
    # Update existing settings with hooks
    jq --arg bin "$COMPANION_BIN" '
      .hooks.PermissionRequest = [{"matcher": "", "hooks": [{"type": "command", "command": ($bin + " attention 5")}]}] |
      .hooks.Notification = [{"matcher": "", "hooks": [{"type": "command", "command": ($bin + " attention 3")}]}] |
      .hooks.Stop = [{"matcher": "", "hooks": [{"type": "command", "command": ($bin + " success 2")}]}]
    ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
  else
    # Create new settings file with hooks
    jq -n --arg bin "$COMPANION_BIN" '{
      hooks: {
        PermissionRequest: [{"matcher": "", "hooks": [{"type": "command", "command": ($bin + " attention 5")}]}],
        Notification: [{"matcher": "", "hooks": [{"type": "command", "command": ($bin + " attention 3")}]}],
        Stop: [{"matcher": "", "hooks": [{"type": "command", "command": ($bin + " success 2")}]}]
      }
    }' > "$CLAUDE_SETTINGS"
  fi
  echo -e "${GREEN}✓ Hooks configured in ~/.claude/settings.json${NC}"
else
  echo -e "${BLUE}jq not found. Please add hooks manually to ~/.claude/settings.json${NC}"
fi
echo ""

# Step 6: Launch the app
echo -e "${BLUE}Step 6: Launching Code Companion...${NC}"
open "$APP_BUNDLE"
echo -e "${GREEN}✓ Code Companion is running${NC}"
echo ""

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code to connect"
echo "2. (Optional) Add to Login Items: System Settings → General → Login Items"
