#!/usr/bin/env bash
set -euo pipefail

: "${SITE_SLUG:?SITE_SLUG is required (example: agentstvorazvitiya)}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> build-one: SITE_SLUG=$SITE_SLUG"

SRC_CONTENT_DIR="$ROOT/content/sites/$SITE_SLUG"
SRC_DATA_FILE="$ROOT/data/sites/$SITE_SLUG.json"

if [ ! -d "$SRC_CONTENT_DIR" ]; then
  echo "ERROR: content/sites/$SITE_SLUG not found"
  exit 1
fi

if [ ! -f "$SRC_DATA_FILE" ]; then
  echo "ERROR: data/sites/$SITE_SLUG.json not found"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
BUILD_ROOT="$TMP_DIR/build"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "==> Copying project into temp workspace: $BUILD_ROOT"
mkdir -p "$BUILD_ROOT"

cp -R "$ROOT/." "$BUILD_ROOT/"

rm -rf "$BUILD_ROOT/.git"
rm -rf "$BUILD_ROOT/public"
rm -rf "$BUILD_ROOT/resources"
rm -rf "$BUILD_ROOT/node_modules"
rm -f "$BUILD_ROOT/.hugo_build.lock"

if [ ! -d "$BUILD_ROOT/content/sites/$SITE_SLUG" ]; then
  echo "ERROR: temp copy missing content/sites/$SITE_SLUG"
  exit 1
fi

if [ ! -f "$BUILD_ROOT/data/sites/$SITE_SLUG.json" ]; then
  echo "ERROR: temp copy missing data/sites/$SITE_SLUG.json"
  exit 1
fi

echo "==> Shrinking content/sites to single slug"
find "$BUILD_ROOT/content/sites" -mindepth 1 -maxdepth 1 -type d ! -name "$SITE_SLUG" -exec rm -rf {} +

echo "==> Shrinking data/sites to single slug json"
find "$BUILD_ROOT/data/sites" -type f -name "*.json" ! -name "${SITE_SLUG}.json" -delete

echo "==> Rebuilding content/_index.md from selected slug"
cp "$BUILD_ROOT/content/sites/$SITE_SLUG/index.md" "$BUILD_ROOT/content/_index.md"

echo "==> Resolving domain from JSON"
SITE_DOMAIN="$(python3 - <<PY
import json
with open("$BUILD_ROOT/data/sites/$SITE_SLUG.json", "r", encoding="utf-8") as f:
    data = json.load(f)
print(data.get("domain_russia", "").strip())
PY
)"

if [ -z "$SITE_DOMAIN" ]; then
  echo "ERROR: domain_russia not found in data/sites/$SITE_SLUG.json"
  exit 1
fi

echo "==> Using baseURL: https://$SITE_DOMAIN/"

echo "==> Cleaning previous public output"
rm -rf "$ROOT/public"

echo "==> Running hugo --minify"
hugo \
  --source "$BUILD_ROOT" \
  --destination "$ROOT/public" \
  --baseURL "https://$SITE_DOMAIN/" \
  --minify

echo "==> Cleaning extra Hugo outputs"
rm -rf "$ROOT/public/sites"
rm -rf "$ROOT/public/tags"
rm -rf "$ROOT/public/categories"
rm -f "$ROOT/public/index.xml"

echo "==> Done: built single-site for $SITE_SLUG"