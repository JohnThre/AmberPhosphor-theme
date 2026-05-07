#!/bin/bash

# Regenerates and validates generated AmberPhosphor theme files.
# License: GPL v3+

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

plist_files=(
    "terminal/AmberPhosphor.terminal"
    "terminal/AmberPhosphor-ANSI.terminal"
    "iterm2/AmberPhosphor.itermcolors"
    "iterm2/AmberPhosphor-ANSI.itermcolors"
)

deterministic_files=(
    "iterm2/AmberPhosphor.itermcolors"
    "iterm2/AmberPhosphor-ANSI.itermcolors"
)

swift terminal/generate-terminal-themes.swift

plutil -lint "${plist_files[@]}"

# Terminal.app profiles embed AppKit NSKeyedArchiver data that is not
# byte-stable across macOS runner versions. iTerm2 plists are deterministic.
git diff --exit-code -- "${deterministic_files[@]}"
