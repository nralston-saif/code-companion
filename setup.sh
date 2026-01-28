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

# Step 4: Show configuration instructions
echo -e "${BLUE}Step 4: Configuration${NC}"
echo ""
echo "Add the following to your Claude Code MCP settings:"
echo "(Usually at ~/.claude/claude_desktop_config.json)"
echo ""
echo -e "${GREEN}{"
echo '  "mcpServers": {'
echo '    "code-companion": {'
echo "      \"command\": \"node\","
echo "      \"args\": [\"$SCRIPT_DIR/mcp-server/dist/index.js\"]"
echo '    }'
echo '  }'
echo -e "}${NC}"
echo ""

# Step 5: Launch instructions
echo -e "${BLUE}To start:${NC}"
echo "1. Launch the companion app:"
echo "   open $APP_BUNDLE"
echo ""
echo "2. Add to Login Items (optional):"
echo "   System Settings → General → Login Items → Add CodeCompanion.app"
echo ""
echo "3. Restart Claude Code to load the MCP server"
echo ""

echo -e "${GREEN}🎉 Setup complete!${NC}"
