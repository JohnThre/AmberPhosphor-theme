#!/bin/bash

# Regenerates and validates generated AmberPhosphor theme files.
# License: GPL v3+

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

generated_files=(
    "terminal/AmberPhosphor.terminal"
    "terminal/AmberPhosphor-ANSI.terminal"
    "iterm2/AmberPhosphor.itermcolors"
    "iterm2/AmberPhosphor-ANSI.itermcolors"
)

swift terminal/generate-terminal-themes.swift

plutil -lint "${generated_files[@]}"

git diff --exit-code -- "${generated_files[@]}"
