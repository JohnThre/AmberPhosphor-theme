#!/bin/bash

# Creates and pushes a signed release tag for AmberPhosphor.
# License: GPL v3+

set -euo pipefail

SIGNING_KEY="FEA322F2C85C0E17"

usage() {
    echo "Usage: $0 vX.Y.Z" >&2
}

if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

version="$1"

if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    usage
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree is dirty; commit or stash changes before releasing." >&2
    exit 1
fi

branch="$(git branch --show-current)"
if [[ "$branch" != "main" ]]; then
    echo "Release must be run from main; current branch is '$branch'." >&2
    exit 1
fi

if ! git rev-parse --verify --quiet origin/main >/dev/null; then
    echo "origin/main does not exist; fetch origin before releasing." >&2
    exit 1
fi

head_sha="$(git rev-parse HEAD)"
origin_main_sha="$(git rev-parse origin/main)"
if [[ "$head_sha" != "$origin_main_sha" ]]; then
    echo "HEAD must match origin/main before releasing." >&2
    echo "HEAD:        $head_sha" >&2
    echo "origin/main: $origin_main_sha" >&2
    exit 1
fi

scripts/validate-themes.sh

echo "About to create and push signed release tag $version at commit $head_sha."
read -r -p "Type 'yes' to continue: " confirmation
if [[ "$confirmation" != "yes" ]]; then
    echo "Release cancelled." >&2
    exit 1
fi

git -c user.signingkey="$SIGNING_KEY" tag -s "$version" -m "AmberPhosphor $version"
git tag -v "$version"
git push origin "$version"

echo "Pushed signed release tag $version to origin."
