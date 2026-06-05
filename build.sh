#!/usr/bin/env bash
# Usage: ./build.sh [--install]
#   --install  also copies the zip to the Factorio mods folder
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION=$(grep '"version"' info.json | sed 's/.*"version": *"\(.*\)".*/\1/')
MOD_NAME="armor-adventure"
ZIP_NAME="${MOD_NAME}_${VERSION}.zip"
DIST_DIR="$SCRIPT_DIR/dist"

mkdir -p "$DIST_DIR"

echo "Building $ZIP_NAME from HEAD..."
git archive --format=zip --prefix="${MOD_NAME}/" HEAD -o "$DIST_DIR/$ZIP_NAME"
echo "Built: $DIST_DIR/$ZIP_NAME"

if [[ "${1:-}" == "--install" ]]; then
    FACTORIO_MODS="$APPDATA/Factorio/mods"
    if [ -d "$FACTORIO_MODS" ]; then
        cp "$DIST_DIR/$ZIP_NAME" "$FACTORIO_MODS/"
        echo "Installed to $FACTORIO_MODS/$ZIP_NAME"
    else
        echo "Warning: Factorio mods folder not found at $FACTORIO_MODS"
    fi
fi
