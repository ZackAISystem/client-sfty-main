#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TMP_DIR="$(mktemp -d)"
BUILD_ROOT="$TMP_DIR/build"
PUBLIC_ROOT="$ROOT/public"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "==> Building SFTY main site only from pretty URL content"

mkdir -p "$BUILD_ROOT"
cp -R "$ROOT/." "$BUILD_ROOT/"

rm -rf "$BUILD_ROOT/.git"
rm -rf "$BUILD_ROOT/public"
rm -rf "$BUILD_ROOT/resources"
rm -rf "$BUILD_ROOT/node_modules"
rm -f "$BUILD_ROOT/.hugo_build.lock"

rm -rf "$BUILD_ROOT/content"
mkdir -p "$BUILD_ROOT/content"

# Keep homepage if exists
if [ -f "$ROOT/content/_index.md" ]; then
  cp "$ROOT/content/_index.md" "$BUILD_ROOT/content/_index.md"
fi

# Keep only real main-site URL sections
for section in business fiu government; do
  if [ -d "$ROOT/content/$section" ]; then
    cp -R "$ROOT/content/$section" "$BUILD_ROOT/content/$section"
  fi
done

rm -rf "$PUBLIC_ROOT"

hugo \
  --source "$BUILD_ROOT" \
  --destination "$PUBLIC_ROOT" \
  --baseURL "https://sfty.ai/" \
  --minify

echo "==> Done: SFTY main build"
echo "==> Output: public"
