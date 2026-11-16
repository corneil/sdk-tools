#!/usr/bin/env bash
#
# install-skill.sh - Install gh-stacked-pr skill for AI coding agents
#
# Usage:
#   ./install-skill.sh [--global] [--junie] [--claude] [--devin] ...
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SOURCE="${SCRIPT_DIR}/skills/gh-stacked-pr"

# Fallback if run from a different layout
if [ ! -d "${SKILL_SOURCE}" ]; then
  if [ -f "${SCRIPT_DIR}/SKILL.md" ]; then
    SKILL_SOURCE="${SCRIPT_DIR}"
  else
    echo "Error: Skill source directory not found (expected '${SKILL_SOURCE}')." >&2
    exit 1
  fi
fi

SKILL_NAME="gh-stacked-pr"

# Default configuration
GLOBAL=false
PROJECT_DIR="$(pwd)"
USE_SYMLINK=false
DRY_RUN=false
FORCE=false

# Track selected targets
INSTALL_JUNIE=false
INSTALL_CLAUDE=false
INSTALL_DEVIN=false
INSTALL_CURSOR=false
INSTALL_CODEX=false
INSTALL_COPILOT=false
INSTALL_GEMINI=false
INSTALL_WINDSURF=false
INSTALL_OPENCODE=false
INSTALL_AGENTS=false

usage() {
  cat <<'EOF'
Usage: ./install-skill.sh [OPTIONS] [AGENT_FLAGS...]

Install the gh-stacked-pr skill into the appropriate directory for local (project)
or global (user) agent detection.

Scope Options:
  -g, --global           Install globally for the current user (e.g. ~/.claude/skills, ~/.junie/skills).
                         Default is local (current project directory).
  -p, --project-dir DIR  Target project directory for local installation (default: current directory).

Agent Flags:
  --junie                Install for JetBrains Junie (.junie/skills / ~/.junie/skills)
  --claude               Install for Claude Code (.claude/skills / ~/.claude/skills)
  --devin                Install for Devin (.agents/skills / ~/.agents/skills)
  --cursor               Install for Cursor IDE (.cursor/skills / ~/.cursor/skills)
  --codex                Install for OpenAI Codex (.codex/skills / ~/.codex/skills)
  --copilot              Install for GitHub Copilot CLI (.github/skills / ~/.copilot/skills)
  --gemini               Install for Gemini CLI (.gemini/skills / ~/.gemini/skills)
  --windsurf             Install for Windsurf Cascade (.windsurf/skills / ~/.codeium/windsurf/skills)
  --opencode             Install for OpenCode (.opencode/skills / ~/.config/opencode/skills)
  --agents               Install to standard cross-agent directory (.agents/skills / ~/.agents/skills)
  --all                  Install for all supported agents above

General Options:
  -s, --symlink          Create symbolic links to skill files instead of copying
  -n, --dry-run          Preview actions without creating directories or copying files
  -f, --force            Overwrite existing destination directory without warning
  -h, --help             Show this help message and exit

Examples:
  ./install-skill.sh --junie                      # Local project install for Junie
  ./install-skill.sh --claude --devin             # Local project install for Claude Code and Devin
  ./install-skill.sh --global --junie --claude    # Global user install for Junie and Claude Code
  ./install-skill.sh --global --all               # Global user install for all supported agents
  ./install-skill.sh -p /path/to/repo --claude    # Local install targeted at a specific repo
EOF
}

# Parse command-line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -g|--global)
      GLOBAL=true
      shift
      ;;
    -p|--project-dir)
      if [ $# -lt 2 ]; then
        echo "Error: --project-dir requires a directory path." >&2
        exit 1
      fi
      PROJECT_DIR="$2"
      shift 2
      ;;
    --project-dir=*)
      PROJECT_DIR="${1#*=}"
      shift
      ;;
    --junie)
      INSTALL_JUNIE=true
      shift
      ;;
    --claude|--claude-code)
      INSTALL_CLAUDE=true
      shift
      ;;
    --devin)
      INSTALL_DEVIN=true
      shift
      ;;
    --cursor)
      INSTALL_CURSOR=true
      shift
      ;;
    --codex)
      INSTALL_CODEX=true
      shift
      ;;
    --copilot|--github-copilot)
      INSTALL_COPILOT=true
      shift
      ;;
    --gemini|--antigravity)
      INSTALL_GEMINI=true
      shift
      ;;
    --windsurf)
      INSTALL_WINDSURF=true
      shift
      ;;
    --opencode)
      INSTALL_OPENCODE=true
      shift
      ;;
    --agents|--cross-agent)
      INSTALL_AGENTS=true
      shift
      ;;
    --all)
      INSTALL_JUNIE=true
      INSTALL_CLAUDE=true
      INSTALL_DEVIN=true
      INSTALL_CURSOR=true
      INSTALL_CODEX=true
      INSTALL_COPILOT=true
      INSTALL_GEMINI=true
      INSTALL_WINDSURF=true
      INSTALL_OPENCODE=true
      INSTALL_AGENTS=true
      shift
      ;;
    -s|--symlink)
      USE_SYMLINK=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run '$0 --help' for usage and options." >&2
      exit 1
      ;;
  esac
done

# Ensure at least one agent was selected
if [ "$INSTALL_JUNIE" = false ] && \
   [ "$INSTALL_CLAUDE" = false ] && \
   [ "$INSTALL_DEVIN" = false ] && \
   [ "$INSTALL_CURSOR" = false ] && \
   [ "$INSTALL_CODEX" = false ] && \
   [ "$INSTALL_COPILOT" = false ] && \
   [ "$INSTALL_GEMINI" = false ] && \
   [ "$INSTALL_WINDSURF" = false ] && \
   [ "$INSTALL_OPENCODE" = false ] && \
   [ "$INSTALL_AGENTS" = false ]; then
  echo "Error: No target agent specified." >&2
  echo "Please specify at least one agent (e.g. --junie, --claude, --devin, --all)." >&2
  echo "Run '$0 --help' for usage and options." >&2
  exit 1
fi

# Define target paths
TARGET_PATHS=()

if [ "$GLOBAL" = true ]; then
  BASE_DIR="${HOME}"

  # Junie supports JUNIE_HOME if set, otherwise ~/.junie
  JUNIE_BASE="${JUNIE_HOME:-${HOME}/.junie}"

  [ "$INSTALL_JUNIE" = true ] && TARGET_PATHS+=("${JUNIE_BASE}/skills/${SKILL_NAME}")
  [ "$INSTALL_CLAUDE" = true ] && TARGET_PATHS+=("${BASE_DIR}/.claude/skills/${SKILL_NAME}")
  [ "$INSTALL_DEVIN" = true ] && TARGET_PATHS+=("${BASE_DIR}/.agents/skills/${SKILL_NAME}")
  [ "$INSTALL_CURSOR" = true ] && TARGET_PATHS+=("${BASE_DIR}/.cursor/skills/${SKILL_NAME}")
  [ "$INSTALL_CODEX" = true ] && TARGET_PATHS+=("${BASE_DIR}/.codex/skills/${SKILL_NAME}")
  [ "$INSTALL_COPILOT" = true ] && TARGET_PATHS+=("${BASE_DIR}/.copilot/skills/${SKILL_NAME}")
  [ "$INSTALL_GEMINI" = true ] && TARGET_PATHS+=("${BASE_DIR}/.gemini/skills/${SKILL_NAME}")
  [ "$INSTALL_WINDSURF" = true ] && TARGET_PATHS+=("${BASE_DIR}/.codeium/windsurf/skills/${SKILL_NAME}")
  [ "$INSTALL_OPENCODE" = true ] && TARGET_PATHS+=("${BASE_DIR}/.config/opencode/skills/${SKILL_NAME}")
  [ "$INSTALL_AGENTS" = true ] && TARGET_PATHS+=("${BASE_DIR}/.agents/skills/${SKILL_NAME}")
else
  BASE_DIR="${PROJECT_DIR}"

  [ "$INSTALL_JUNIE" = true ] && TARGET_PATHS+=("${BASE_DIR}/.junie/skills/${SKILL_NAME}")
  [ "$INSTALL_CLAUDE" = true ] && TARGET_PATHS+=("${BASE_DIR}/.claude/skills/${SKILL_NAME}")
  [ "$INSTALL_DEVIN" = true ] && TARGET_PATHS+=("${BASE_DIR}/.agents/skills/${SKILL_NAME}")
  [ "$INSTALL_CURSOR" = true ] && TARGET_PATHS+=("${BASE_DIR}/.cursor/skills/${SKILL_NAME}")
  [ "$INSTALL_CODEX" = true ] && TARGET_PATHS+=("${BASE_DIR}/.codex/skills/${SKILL_NAME}")
  [ "$INSTALL_COPILOT" = true ] && TARGET_PATHS+=("${BASE_DIR}/.github/skills/${SKILL_NAME}")
  [ "$INSTALL_GEMINI" = true ] && TARGET_PATHS+=("${BASE_DIR}/.gemini/skills/${SKILL_NAME}")
  [ "$INSTALL_WINDSURF" = true ] && TARGET_PATHS+=("${BASE_DIR}/.windsurf/skills/${SKILL_NAME}")
  [ "$INSTALL_OPENCODE" = true ] && TARGET_PATHS+=("${BASE_DIR}/.opencode/skills/${SKILL_NAME}")
  [ "$INSTALL_AGENTS" = true ] && TARGET_PATHS+=("${BASE_DIR}/.agents/skills/${SKILL_NAME}")
fi

# Deduplicate paths
UNIQUE_PATHS=()
for path in "${TARGET_PATHS[@]}"; do
  already_added=false
  for existing in "${UNIQUE_PATHS[@]-}"; do
    if [ "$existing" = "$path" ]; then
      already_added=true
      break
    fi
  done
  if [ "$already_added" = false ]; then
    UNIQUE_PATHS+=("$path")
  fi
done

# Perform installation
echo "Installing ${SKILL_NAME} skill..."
echo "  Scope:  $([ "$GLOBAL" = true ] && echo "Global (user: ${HOME})" || echo "Local (project: ${PROJECT_DIR})")"
echo "  Source: ${SKILL_SOURCE}"
echo ""

install_target() {
  local target="$1"

  if [ "$DRY_RUN" = true ]; then
    if [ "$USE_SYMLINK" = true ]; then
      echo "[dry-run] Would symlink '${SKILL_SOURCE}' -> '${target}'"
    else
      echo "[dry-run] Would copy skill files into '${target}'"
    fi
    return 0
  fi

  if [ "$USE_SYMLINK" = true ]; then
    mkdir -p "$(dirname "$target")"
    if [ -e "$target" ] || [ -L "$target" ]; then
      rm -rf "$target"
    fi
    ln -s "$SKILL_SOURCE" "$target"
    echo "✓ Symlinked to: ${target}"
  else
    if [ "$FORCE" = true ] && [ -d "$target" ]; then
      rm -rf "$target"
    fi
    mkdir -p "$target"
    cp -R "${SKILL_SOURCE}/." "${target}/"
    echo "✓ Installed to: ${target}"
  fi
}

for dest in "${UNIQUE_PATHS[@]}"; do
  install_target "$dest"
done

echo ""
if [ "$DRY_RUN" = true ]; then
  echo "Dry run complete. No files were modified."
else
  echo "Installation complete!"
fi
