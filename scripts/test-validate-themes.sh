#!/bin/bash

# Regression tests for generated theme validation behavior.
# License: GPL v3+

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_REPO="$TEST_ROOT/repo"
TEST_BIN="$TEST_ROOT/bin"

mkdir -p "$TEST_REPO/scripts" "$TEST_REPO/terminal" "$TEST_REPO/iterm2" "$TEST_BIN"

cp "$REPO_ROOT/scripts/validate-themes.sh" "$TEST_REPO/scripts/validate-themes.sh"
chmod +x "$TEST_REPO/scripts/validate-themes.sh"

printf 'committed terminal\n' > "$TEST_REPO/terminal/AmberPhosphor.terminal"
printf 'committed terminal ansi\n' > "$TEST_REPO/terminal/AmberPhosphor-ANSI.terminal"
printf 'committed iterm2\n' > "$TEST_REPO/iterm2/AmberPhosphor.itermcolors"
printf 'committed iterm2 ansi\n' > "$TEST_REPO/iterm2/AmberPhosphor-ANSI.itermcolors"

cat > "$TEST_BIN/plutil" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "-lint" ]]; then
    shift
    for f in "$@"; do
        echo "$f: OK"
    done
    exit 0
fi

echo "unexpected plutil invocation: $*" >&2
exit 1
EOF

cat > "$TEST_BIN/swift" <<'EOF'
#!/bin/bash
if [[ "${1:-}" != "terminal/generate-terminal-themes.swift" ]]; then
    echo "unexpected swift invocation: $*" >&2
    exit 1
fi

case "${VALIDATE_FIXTURE_MODE:-}" in
    terminal-drift)
        printf 'runner-specific terminal\n' > terminal/AmberPhosphor.terminal
        printf 'runner-specific terminal ansi\n' > terminal/AmberPhosphor-ANSI.terminal
        ;;
    iterm2-drift)
        printf 'changed iterm2\n' > iterm2/AmberPhosphor.itermcolors
        ;;
    *)
        echo "unexpected VALIDATE_FIXTURE_MODE: ${VALIDATE_FIXTURE_MODE:-}" >&2
        exit 1
        ;;
esac
EOF

chmod +x "$TEST_BIN/plutil" "$TEST_BIN/swift"

git -C "$TEST_REPO" init -q
git -C "$TEST_REPO" config user.email "test@example.invalid"
git -C "$TEST_REPO" config user.name "Test"
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -q -m "Initial generated files"

PATH="$TEST_BIN:$PATH" \
    VALIDATE_FIXTURE_MODE=terminal-drift \
    "$TEST_REPO/scripts/validate-themes.sh"

if PATH="$TEST_BIN:$PATH" \
    VALIDATE_FIXTURE_MODE=iterm2-drift \
    "$TEST_REPO/scripts/validate-themes.sh"; then
    echo "Expected iTerm2 generated-file drift to fail validation" >&2
    exit 1
fi
