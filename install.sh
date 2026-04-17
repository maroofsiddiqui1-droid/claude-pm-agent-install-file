#!/bin/bash

# ============================================================
# 1mg Claude PM Toolkit — One-Command Installer
# Mac only. Requires internet connection.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/maroofsiddiqui1-droid/claude-pm-agent-install-file/main/install.sh | bash
# ============================================================

set -e

# ---- Colours -----------------------------------------------
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
info() { echo -e "  ${YELLOW}→${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; exit 1; }
section() { echo -e "\n${BOLD}$1${RESET}"; }

# ---- Config ------------------------------------------------
GITHUB_REPO="https://github.com/maroofsiddiqui1-droid/1mg-claude-code-toolkit.git"
INSTALL_DIR="$HOME/1mg-claude-code"
TOOLKIT_DIR="$INSTALL_DIR/claude-pm-toolkit"
WORKSPACE_DIR="$INSTALL_DIR/claude-workspace"
GLOBAL_CLAUDE_DIR="$HOME/.claude"
GLOBAL_CLAUDE_MD="$GLOBAL_CLAUDE_DIR/CLAUDE.md"
TOOLKIT_MARKER="# 1mg PM Toolkit (auto-installed)"

echo ""
echo -e "${BOLD}============================================${RESET}"
echo -e "${BOLD}  1mg Claude PM Toolkit — Installer        ${RESET}"
echo -e "${BOLD}============================================${RESET}"
echo ""

# ============================================================
# STEP 1 — Homebrew
# ============================================================
section "Step 1/6 — Homebrew"

if command -v brew &> /dev/null; then
    ok "Homebrew already installed"
else
    info "Installing Homebrew (you may be asked for your Mac password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH — works for both Apple Silicon (/opt/homebrew) and Intel (/usr/local)
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        fail "Homebrew installation failed. Please install manually from https://brew.sh and re-run."
    fi
    ok "Homebrew installed"
fi

# ============================================================
# STEP 2 — Node.js
# ============================================================
section "Step 2/6 — Node.js"

MIN_NODE_MAJOR=18

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -ge "$MIN_NODE_MAJOR" ]; then
        ok "Node.js $NODE_VERSION already installed"
    else
        info "Node.js $NODE_VERSION is too old (need v$MIN_NODE_MAJOR+). Upgrading..."
        brew upgrade node || brew install node
        ok "Node.js upgraded"
    fi
else
    info "Installing Node.js..."
    brew install node
    ok "Node.js installed"
fi

# ============================================================
# STEP 3 — Git
# ============================================================
section "Step 3/6 — Git"

if command -v git &> /dev/null; then
    ok "Git already installed ($(git --version))"
else
    info "Installing Git..."
    brew install git
    ok "Git installed"
fi

# ============================================================
# STEP 4 — VS Code
# ============================================================
section "Step 4/6 — VS Code"

if command -v code &> /dev/null; then
    ok "VS Code already installed"
else
    info "Installing VS Code..."
    brew install --cask visual-studio-code
    ok "VS Code installed"
fi

# ============================================================
# STEP 5 — Claude Code
# ============================================================
section "Step 5/6 — Claude Code"

if command -v claude &> /dev/null; then
    info "Claude Code already installed. Updating to latest..."
    npm update -g @anthropic-ai/claude-code 2>/dev/null || true
    ok "Claude Code up to date"
else
    info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installed"
fi

# ============================================================
# STEP 6 — Directory Setup + Clone + Global Skills
# ============================================================
section "Step 6/6 — Setting up workspace"

# Create base directory
mkdir -p "$INSTALL_DIR"

# Clone or update the toolkit
if [ -d "$TOOLKIT_DIR/.git" ]; then
    info "Toolkit already exists. Pulling latest updates..."
    git -C "$TOOLKIT_DIR" pull --quiet
    ok "Toolkit updated"
else
    info "Cloning toolkit from GitHub..."
    git clone --quiet "$GITHUB_REPO" "$TOOLKIT_DIR"
    ok "Toolkit cloned"
fi

# Create empty workspace folder
mkdir -p "$WORKSPACE_DIR"
ok "Workspace folder ready: ~/1mg-claude-code/claude-workspace"

# Register skills globally in ~/.claude/CLAUDE.md
mkdir -p "$GLOBAL_CLAUDE_DIR"
touch "$GLOBAL_CLAUDE_MD"

if grep -qF "$TOOLKIT_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
    ok "Skills already registered globally — no changes needed"
else
    {
        printf "\n%s\n" "$TOOLKIT_MARKER"
        printf "@%s/CLAUDE.md\n" "$TOOLKIT_DIR"
    } >> "$GLOBAL_CLAUDE_MD"
    ok "Skills registered globally in ~/.claude/CLAUDE.md"
fi

# ============================================================
# DONE
# ============================================================
echo ""
echo -e "${BOLD}============================================${RESET}"
echo -e "${GREEN}${BOLD}  Installation complete!${RESET}"
echo -e "${BOLD}============================================${RESET}"
echo ""
echo "Your setup:"
echo "  Toolkit   →  ~/1mg-claude-code/claude-pm-toolkit"
echo "  Workspace →  ~/1mg-claude-code/claude-workspace"
echo ""
echo -e "${BOLD}To get started:${RESET}"
echo "  1. Open Terminal"
echo "  2. Run:  cd ~/1mg-claude-code/claude-workspace"
echo "  3. Run:  claude"
echo "  4. On first launch, Claude Code will ask you to log in with your Anthropic account"
echo ""
echo -e "${BOLD}Skills available immediately (type / to see all):${RESET}"
echo "  /prd-writer          Write PRDs"
echo "  /shaping             Shape a product initiative"
echo "  /okrs                Define OKRs"
echo "  /feature-prioritization-assistant  RICE scoring"
echo "  /jobs-to-be-done     Discover user needs"
echo "  ... and 25+ more"
echo ""
echo "To update the toolkit anytime, re-run this installer."
echo ""
