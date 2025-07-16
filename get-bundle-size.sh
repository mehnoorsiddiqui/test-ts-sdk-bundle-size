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
    test-webpack | test-rollup)
      BUNDLE_FILE="$PROJECT_PATH/dist/bundle.js"
      ;;
    test-esbuild)
      BUNDLE_FILE="$PROJECT_PATH/dist/output.js"
      ;;
    *)
      echo "❌ Unknown bundler: $BUNDLER" >&2
      exit 1
      ;;
  esac

  if [[ -f "$BUNDLE_FILE" ]]; then
    du -h "$BUNDLE_FILE" | cut -f1
  else
    echo "0B"
  fi
}

# Entry point
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <bundler> <project-dir>" >&2
  exit 1
fi

get_bundle_size "$1" "$2"
