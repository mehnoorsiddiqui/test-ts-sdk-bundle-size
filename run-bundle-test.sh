#!/bin/bash
set -e

# Resolve script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/get-bundle-size.sh"

BUNDLE_TEST_DIR="$SCRIPT_DIR"
OUTPUT_JSON="$BUNDLE_TEST_DIR/bundle-sizes.json"
SDK_BASE_DIR="$ROOT_DIR/GeneratedSDKs/TS_GENERIC_LIB"
declare -A BUNDLE_SIZES

echo "📦 Ensuring test-ts-sdk-bundle-size repo is present in $BUNDLE_TEST_DIR"
# No need to clone again — assuming we're already in the right repo

SDK_DIRS=$(find "$SDK_BASE_DIR" -mindepth 1 -maxdepth 1 -type d)
if [[ -z "$SDK_DIRS" ]]; then
  echo "❌ No SDKs found in $SDK_BASE_DIR"
  exit 1
fi

for SDK_DIR in $SDK_DIRS; do
  echo "🔁 Processing SDK: $SDK_DIR"

  EXAMPLE_DIR="$SDK_DIR/src/examples"
  SAMPLE_FILE=$(find "$EXAMPLE_DIR" -type f | head -n 1)

  cd "$SDK_DIR"
  PACKAGE_NAME=$(node -p "require('./package.json').name")
  cd "$ROOT_DIR" > /dev/null

  if [[ -f "$SAMPLE_FILE" ]]; then
    for PROJECT in test-webpack test-rollup test-esbuild test-vite; do
      if [[ "$PROJECT" == "test-vite" ]]; then
        TARGET_FILE="$BUNDLE_TEST_DIR/$PROJECT/src/main.ts"
      else
        TARGET_FILE="$BUNDLE_TEST_DIR/$PROJECT/src/index.ts"
      fi

      echo "✏️ Injecting code into $PROJECT..."
      cp "$SAMPLE_FILE" "$TARGET_FILE"
      sed -i "s#from '\(\.\.\/\)\+'#from '$PACKAGE_NAME'#g" "$TARGET_FILE"

      cd "$BUNDLE_TEST_DIR/$PROJECT"
      OLD_SDK=$(jq -r '.dependencies | to_entries[] | select(.value | endswith(".tgz")) | .key' package.json)
      if [[ -n "$OLD_SDK" ]]; then
        npm uninstall "$OLD_SDK"
      fi
      cd "$BUNDLE_TEST_DIR"
    done
  else
    echo "⚠️ No sample file found in $EXAMPLE_DIR"
    continue
  fi

  echo "📦 Installing SDK dependencies..."
  cd "$SDK_DIR"
  npm install

  echo "📦 Packing SDK..."
  TARBALL_PATH=$(npm pack --silent)
  TARBALL_ABS_PATH="$(pwd)/$TARBALL_PATH"
  cd "$BUNDLE_TEST_DIR"

  for PROJECT in test-webpack test-rollup test-esbuild test-vite; do
    echo "📦 Installing $PACKAGE_NAME into $PROJECT..."
    cd "$BUNDLE_TEST_DIR/$PROJECT"
    npm install "$TARBALL_ABS_PATH"

    echo "🏗️ Building $PROJECT..."
    npm run build || {
      echo "❌ Build failed for $PROJECT"
      exit 1
    }
    echo "✅ $PROJECT built successfully"
    cd "$BUNDLE_TEST_DIR"

    SIZE=$(get_bundle_size "$PROJECT" "$BUNDLE_TEST_DIR/$PROJECT")
    echo "📦 Bundle size for $PACKAGE_NAME in $PROJECT: $SIZE"
    BUNDLE_SIZES["$PACKAGE_NAME|$PROJECT"]="$SIZE"
  done
done

echo "📝 Writing bundle sizes to $OUTPUT_JSON..."
TMP_JSON="{}"
for key in "${!BUNDLE_SIZES[@]}"; do
  IFS='|' read -r sdk bundler <<< "$key"
  bundler=${bundler#test-}
  size="${BUNDLE_SIZES[$key]}"
  TMP_JSON=$(echo "$TMP_JSON" | jq --arg sdk "$sdk" --arg bundler "$bundler" --arg size "$size" '
    .[$sdk] = (.[$sdk] // {}) | .[$sdk][$bundler] = $size
  ')
done

echo "$TMP_JSON" | jq '.' > "$OUTPUT_JSON"
echo "✅ Bundle sizes written to $OUTPUT_JSON"
