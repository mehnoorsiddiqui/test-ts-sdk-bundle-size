#!/bin/bash
set -e

source ./get-bundle-size.sh

ROOT_DIR=$(pwd)
BUNDLE_TEST_REPO="https://github.com/mehnoorsiddiqui/test-ts-sdk-bundle-size.git"
BUNDLE_TEST_DIR="test-ts-sdk-bundle-size"
OUTPUT_JSON="bundle-sizes.json"
declare -A BUNDLE_SIZES
declare -A JOB_PIDS

echo "📦 Cloning test-ts-sdk-bundle-size repo..."
rm -rf "$BUNDLE_TEST_DIR"
git clone --branch main "$BUNDLE_TEST_REPO" "$BUNDLE_TEST_DIR"

SDK_BASE_DIR="./GeneratedSDKs/TS_GENERIC_LIB"
SDK_DIRS=$(find "$SDK_BASE_DIR" -mindepth 1 -maxdepth 1 -type d)

if [[ -z "$SDK_DIRS" ]]; then
  echo "❌ No SDKs found in $SDK_BASE_DIR"
  exit 1
fi

run_bundler() {
  local PROJECT=$1
  local PACKAGE_NAME=$2
  local TARBALL_ABS_PATH=$3
  local SAMPLE_FILE=$4

  TARGET_FILE="$BUNDLE_TEST_DIR/$PROJECT/src/$( [[ "$PROJECT" == "test-vite" ]] && echo "main.ts" || echo "index.ts" )"

  echo "✏️ Injecting code into $PROJECT..."
  cp "$SAMPLE_FILE" "$TARGET_FILE"
  sed -i "s#from '\(\.\.\/\)\+'#from '$PACKAGE_NAME'#g" "$TARGET_FILE"

  cd "$ROOT_DIR/$BUNDLE_TEST_DIR/$PROJECT"
  OLD_SDK=$(jq -r '.dependencies | to_entries[] | select(.value | endswith(".tgz")) | .key' package.json)
  if [[ -n "$OLD_SDK" ]]; then
    npm uninstall "$OLD_SDK"
  fi

  echo "📦 Installing $PACKAGE_NAME into $PROJECT..."
  npm install "$TARBALL_ABS_PATH"

  echo "🏗️ Building $PROJECT..."
  if ! npm run build; then
    echo "❌ Build failed for $PROJECT"
    exit 1
  fi

  SIZE=$(get_bundle_size "$PROJECT" "$ROOT_DIR/$BUNDLE_TEST_DIR/$PROJECT")
  echo "📦 Bundle size for $PACKAGE_NAME in $PROJECT: $SIZE"
  BUNDLE_SIZES["$PACKAGE_NAME|$PROJECT"]="$SIZE"
}

for SDK_DIR in $SDK_DIRS; do
  echo "🔁 Processing SDK: $SDK_DIR"

  EXAMPLE_DIR="$SDK_DIR/src/examples"
  SAMPLE_FILE=$(find "$EXAMPLE_DIR" -type f | head -n 1)

  cd "$SDK_DIR"
  PACKAGE_NAME=$(node -p "require('./package.json').name")
  cd "$ROOT_DIR" > /dev/null

  if [[ -f "$SAMPLE_FILE" ]]; then
    echo "📦 Installing SDK dependencies..."
    cd "$SDK_DIR"
    npm install

    echo "📦 Packing SDK..."
    TARBALL_PATH=$(npm pack --silent)
    TARBALL_ABS_PATH="$(pwd)/$TARBALL_PATH"
    cd "$ROOT_DIR"

    for PROJECT in test-vite test-webpack test-rollup test-esbuild; do
      run_bundler "$PROJECT" "$PACKAGE_NAME" "$TARBALL_ABS_PATH" "$SAMPLE_FILE" &
      JOB_PIDS["$PROJECT"]=$!
    done

    # Wait for all parallel jobs to finish
    for PROJECT in "${!JOB_PIDS[@]}"; do
      PID=${JOB_PIDS[$PROJECT]}
      wait "$PID" || { echo "❌ $PROJECT failed"; exit 1; }
    done

    unset JOB_PIDS
  else
    echo "⚠️ No sample file found in $EXAMPLE_DIR"
    continue
  fi
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

