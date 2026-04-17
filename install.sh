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
CYAN='\033[0;36m'
RESET='\033[0m'

ok()      { echo -e "  ${GREEN}✓${RESET} $1"; }
info()    { echo -e "  ${YELLOW}→${RESET} $1"; }
fail()    { echo -e "  ${RED}✗${RESET} $1"; exit 1; }
skipped() { echo -e "  ${CYAN}⤼${RESET} $1 — skipped"; }
section() { echo -e "\n${BOLD}$1${RESET}"; }

# ---- Config ------------------------------------------------
GITHUB_REPO="maroofsiddiqui1-droid/1mg-claude-code-toolkit"
INSTALL_DIR="$HOME/1mg-claude-code"
TOOLKIT_DIR="$INSTALL_DIR/claude-pm-toolkit"
WORKSPACE_DIR="$INSTALL_DIR/claude-workspace"
GLOBAL_CLAUDE_DIR="$HOME/.claude"
GLOBAL_CLAUDE_MD="$GLOBAL_CLAUDE_DIR/CLAUDE.md"
TOOLKIT_MARKER="# 1mg PM Toolkit (auto-installed)"

# ---- Confirm helper ----------------------------------------
# Reads from /dev/tty so it works even when piped via curl | bash
confirm() {
    local prompt="$1"
    local answer
    echo -e "  ${CYAN}?${RESET} ${prompt} [y/n]: \c" > /dev/tty
    read -r answer < /dev/tty
    [[ "$answer" =~ ^[Yy]$ ]]
}

echo ""
echo -e "${BOLD}============================================${RESET}"
echo -e "${BOLD}  1mg Claude PM Toolkit — Installer        ${RESET}"
echo -e "${BOLD}============================================${RESET}"
echo ""
echo -e "  You'll be asked before each step. Press ${BOLD}y${RESET} to install, ${BOLD}n${RESET} to skip."
echo ""

# ============================================================
# STEP 1 — Homebrew
# ============================================================
section "Step 1/7 — Homebrew"

if command -v brew &> /dev/null; then
    ok "Homebrew already installed"
else
    if confirm "Homebrew is not installed. Install it now?"; then
        info "Installing Homebrew (you may be asked for your Mac password)..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        else
            fail "Homebrew installation failed. Please install manually from https://brew.sh and re-run."
        fi
        ok "Homebrew installed"
    else
        skipped "Homebrew"
    fi
fi

# ============================================================
# STEP 2 — Node.js
# ============================================================
section "Step 2/7 — Node.js"

MIN_NODE_MAJOR=18

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -ge "$MIN_NODE_MAJOR" ]; then
        ok "Node.js $NODE_VERSION already installed"
    else
        if confirm "Node.js $NODE_VERSION is too old (need v$MIN_NODE_MAJOR+). Upgrade it?"; then
            brew upgrade node || brew install node
            ok "Node.js upgraded"
        else
            skipped "Node.js upgrade"
        fi
    fi
else
    if confirm "Node.js is not installed. Install it now?"; then
        info "Installing Node.js..."
        brew install node
        ok "Node.js installed"
    else
        skipped "Node.js"
    fi
fi

# ============================================================
# STEP 3 — Git
# ============================================================
section "Step 3/7 — Git"

if command -v git &> /dev/null; then
    ok "Git already installed ($(git --version))"
else
    if confirm "Git is not installed. Install it now?"; then
        info "Installing Git..."
        brew install git
        ok "Git installed"
    else
        skipped "Git"
    fi
fi

# ============================================================
# STEP 4 — GitHub CLI (gh)
# ============================================================
section "Step 4/7 — GitHub CLI"

if command -v gh &> /dev/null; then
    ok "GitHub CLI already installed ($(gh --version | head -1))"
    if ! gh auth status &> /dev/null; then
        if confirm "GitHub CLI is installed but you're not logged in. Log in now?"; then
            info "Opening GitHub in your browser to authenticate..."
            gh auth login --web < /dev/tty
            ok "GitHub authenticated"
        else
            skipped "GitHub login"
        fi
    else
        ok "GitHub already authenticated"
    fi
else
    if confirm "GitHub CLI is not installed. Install and log in now? (needed to clone the private toolkit repo)"; then
        info "Installing GitHub CLI..."
        brew install gh
        ok "GitHub CLI installed"
        info "Opening GitHub in your browser to authenticate..."
        gh auth login --web < /dev/tty
        ok "GitHub authenticated"
    else
        skipped "GitHub CLI"
    fi
fi

# ============================================================
# STEP 5 — VS Code
# ============================================================
section "Step 5/7 — VS Code"

if command -v code &> /dev/null; then
    ok "VS Code already installed"
else
    if confirm "VS Code is not installed. Install it now?"; then
        info "Installing VS Code..."
        brew install --cask visual-studio-code
        ok "VS Code installed"
    else
        skipped "VS Code"
    fi
fi

# ============================================================
# STEP 6 — Claude Code
# ============================================================
section "Step 6/7 — Claude Code"

if command -v claude &> /dev/null; then
    if confirm "Claude Code is already installed. Update it to the latest version?"; then
        info "Updating Claude Code..."
        npm update -g @anthropic-ai/claude-code 2>/dev/null || true
        ok "Claude Code up to date"
    else
        skipped "Claude Code update"
    fi
else
    if confirm "Claude Code is not installed. Install it now?"; then
        info "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        ok "Claude Code installed"
    else
        skipped "Claude Code"
    fi
fi

# ============================================================
# STEP 7 — Directory Setup + Clone + Global Skills
# ============================================================
section "Step 7/7 — Setting up workspace"

if confirm "Set up the 1mg PM Toolkit workspace and clone the toolkit repo?"; then
    mkdir -p "$INSTALL_DIR"

    if [ -d "$TOOLKIT_DIR/.git" ]; then
        info "Toolkit already exists. Pulling latest updates..."
        git -C "$TOOLKIT_DIR" pull --quiet
        ok "Toolkit updated"
    else
        info "Cloning toolkit from GitHub..."
        if command -v gh &> /dev/null && gh auth status &> /dev/null; then
            gh repo clone "$GITHUB_REPO" "$TOOLKIT_DIR" -- --quiet
        else
            git clone --quiet "https://github.com/${GITHUB_REPO}.git" "$TOOLKIT_DIR"
        fi
        ok "Toolkit cloned"
    fi

    mkdir -p "$WORKSPACE_DIR"
    ok "Workspace folder ready: ~/1mg-claude-code/claude-workspace"

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
else
    skipped "Workspace setup"
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
