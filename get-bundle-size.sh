#!/bin/bash
set -e

get_bundle_size() {
  local BUNDLER=$1
  local PROJECT_PATH=$2
  local BUNDLE_FILE=""

  case $BUNDLER in
    test-vite)
      BUNDLE_FILE=$(find "$PROJECT_PATH/dist/assets" -name "*.js" | head -n 1)
      ;;
    test-webpack)
      BUNDLE_FILE="$PROJECT_PATH/dist/bundle.js"
      ;;
    test-rollup)
      BUNDLE_FILE="$PROJECT_PATH/dist/bundle.js"
      ;;
    test-esbuild)
      BUNDLE_FILE="$PROJECT_PATH/dist/output.js"
      ;;
    *)
      echo "❌ Unknown bundler: $BUNDLER"
      exit 1
      ;;
  esac

  if [[ -f "$BUNDLE_FILE" ]]; then
    du -h "$BUNDLE_FILE" | cut -f1
  else
    echo "0B"
  fi
}
