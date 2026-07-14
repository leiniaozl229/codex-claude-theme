#!/bin/bash
# Creates a locally themed copy of the installed Codex client.
set -euo pipefail

if [ -d "/Applications/Codex.app" ]; then
  SOURCE_APP="/Applications/Codex.app"
else
  SOURCE_APP="/Applications/ChatGPT.app"
fi
TARGET_APP="$HOME/Applications/Codex Claude Lab.app"
FORCE=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--source /path/to/Codex.app] [--target /path/to/Lab.app] [--force]

By default, copies the installed Codex app and themes only the copy. The
source defaults to /Applications/Codex.app, then falls back to ChatGPT.app
for older installs.
EOF
}

while (($#)); do
  case "$1" in
    --source) SOURCE_APP="$2"; shift 2 ;;
    --target) TARGET_APP="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for command in ditto npx codesign; do
  command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 1; }
done
[ -d "$SOURCE_APP" ] || { echo "Codex app not found: $SOURCE_APP" >&2; exit 1; }

if [ -e "$TARGET_APP" ] && [ "$FORCE" != true ]; then
  echo "Target already exists: $TARGET_APP" >&2
  echo "Re-run with --force to replace only the themed copy." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSET_DIR="$SCRIPT_DIR/assets"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-claude-theme.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

[ -f "$ASSET_DIR/claude-code-lab.css" ] || { echo "Theme assets are incomplete." >&2; exit 1; }

if [ -e "$TARGET_APP" ]; then rm -rf "$TARGET_APP"; fi
mkdir -p "$(dirname "$TARGET_APP")"
ditto "$SOURCE_APP" "$TARGET_APP"

ASAR="$TARGET_APP/Contents/Resources/app.asar"
WEBVIEW="$TMP_DIR/unpacked/webview"
npx --yes @electron/asar extract "$ASAR" "$TMP_DIR/unpacked"

[ -f "$WEBVIEW/index.html" ] || { echo "Unsupported Codex package layout." >&2; exit 1; }
mkdir -p "$WEBVIEW/assets"
find "$ASSET_DIR" -maxdepth 1 -type f ! -name '*.example' -exec cp {} "$WEBVIEW/assets/" \;

WORDMARK_ENABLED=false
if [ -f "$ASSET_DIR/custom-wordmark-dark.svg" ] && [ -f "$ASSET_DIR/custom-wordmark-light.svg" ]; then
  WORDMARK_ENABLED=true
fi
printf 'globalThis.__CODEX_CLAUDE_THEME_WORDMARK__ = %s;\n' "$WORDMARK_ENABLED" > "$WEBVIEW/assets/claude-code-lab-config.js"

INDEX="$WEBVIEW/index.html"
if ! grep -q 'claude-code-lab.css' "$INDEX"; then
  /usr/bin/perl -0pi -e 's!</head>!    <link rel="stylesheet" href="./assets/claude-code-lab.css" />\n    <script src="./assets/claude-code-lab-config.js"></script>\n    <script type="module" crossorigin src="./assets/claude-code-lab.js"></script>\n</head>!' "$INDEX"
fi

npx --yes @electron/asar pack "$TMP_DIR/unpacked" "$ASAR"
codesign --force --deep --sign - "$TARGET_APP"
codesign --verify --deep --strict "$TARGET_APP"
xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true

echo "Installed: $TARGET_APP"
echo "Open it with: open -n \"$TARGET_APP\" --args --user-data-dir=\"$HOME/Library/Application Support/Codex-Claude-Lab\""
