#!/bin/bash

# AmberPhosphor iTerm2 Installation Script
# Opens color presets for import into iTerm2
# License: GPL v3+

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
    Darwin*)
        ;;
    *)
        echo "This script is for macOS. iTerm2 is a macOS application."
        echo "On macOS, run: $0"
        exit 1
        ;;
esac

echo "Installing AmberPhosphor themes for iTerm2..."

for f in AmberPhosphor.itermcolors AmberPhosphor-ANSI.itermcolors; do
    if [[ -f "$SCRIPT_DIR/$f" ]]; then
        open "$SCRIPT_DIR/$f"
        echo "  Opened: $f"
    else
        echo "  Warning: $f not found, skipping"
    fi
done

echo ""
echo "Done. Import the opened presets in iTerm2."
echo "Open iTerm2 > Settings > Profiles > Colors > Color Presets and select AmberPhosphor or AmberPhosphor ANSI."
echo ""
