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

scripts/validate-themes.sh

git config user.signingkey "$SIGNING_KEY"
git tag -s "$version" -m "AmberPhosphor $version"
git tag -v "$version"
git push origin "$version"

echo "Pushed signed release tag $version to origin."
