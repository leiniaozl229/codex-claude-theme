#!/bin/bash
# Creates a locally themed Codex copy, or patches the installed client in place.
set -euo pipefail

SOURCE_APP="/Applications/ChatGPT.app"
TARGET_APP="$HOME/Applications/Codex Claude Lab.app"
FORCE=false
IN_PLACE=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--in-place] [--source /path/to/ChatGPT.app] [--target /path/to/Lab.app] [--force]

By default, copies the installed Codex app and themes the copy. With
--in-place, patches the installed client itself and keeps its existing data,
login, and settings. An original app.asar backup is saved before patching.
EOF
}

while (($#)); do
  case "$1" in
    --source) SOURCE_APP="$2"; shift 2 ;;
    --target) TARGET_APP="$2"; shift 2 ;;
    --in-place) IN_PLACE=true; shift ;;
    --force) FORCE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for command in ditto npx codesign; do
  command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 1; }
done
[ -d "$SOURCE_APP" ] || { echo "Codex app not found: $SOURCE_APP" >&2; exit 1; }

if [ "$IN_PLACE" = true ]; then
  TARGET_APP="$SOURCE_APP"
elif [ -e "$TARGET_APP" ] && [ "$FORCE" != true ]; then
  echo "Target already exists: $TARGET_APP" >&2
  echo "Re-run with --force to replace only the themed copy." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSET_DIR="$SCRIPT_DIR/assets"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-claude-theme.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

[ -f "$ASSET_DIR/claude-code-lab.css" ] || { echo "Theme assets are incomplete." >&2; exit 1; }

if [ "$IN_PLACE" = true ]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SOURCE_APP/Contents/Info.plist" 2>/dev/null || date +%Y%m%d%H%M%S)"
  BACKUP="$HOME/Library/Application Support/Codex Claude Theme/backups/$VERSION/app.asar"
  mkdir -p "$(dirname "$BACKUP")"
  if [ ! -f "$BACKUP" ]; then
    cp "$SOURCE_APP/Contents/Resources/app.asar" "$BACKUP"
    echo "Original resource backup: $BACKUP"
  fi
  if pgrep -f "$SOURCE_APP/Contents/MacOS/ChatGPT" >/dev/null; then
    echo "Codex is running; restart it after this command to load the theme."
  fi
else
  if [ -e "$TARGET_APP" ]; then rm -rf "$TARGET_APP"; fi
  mkdir -p "$(dirname "$TARGET_APP")"
  ditto "$SOURCE_APP" "$TARGET_APP"
fi

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

if [ "$IN_PLACE" = true ]; then
  echo "Patched the installed Codex app: $TARGET_APP"
  echo "Restart Codex to load the theme."
else
  echo "Installed: $TARGET_APP"
  echo "Open it with: open -n \"$TARGET_APP\" --args --user-data-dir=\"$HOME/Library/Application Support/Codex-Claude-Lab\""
fi
