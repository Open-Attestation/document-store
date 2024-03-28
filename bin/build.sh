#!/bin/bash

set -e

workdir=$(pwd)

build_types() {
  cd $workdir

  if [ ! -d "artifacts/src" ]; then
    # Mostly for local development
    npm run build:hh
  fi

  local target="$1"
  echo "Building target: $target"

  if [ -d ".build/types-$target" ]; then
      echo "Cleaning up build directory..."
      rm -rf ".build/types-$target" || echo "Failed to clean up build directory."
  else
      echo "Creating build directory..."
  fi

  mkdir -p ".build/types-$target" && cd ".build/types-$target"

  echo "Build directory created."

  cat <<EOF > package.json
    {
      "name": "@govtechsg/document-store",
      "version": "1.0.0",
      "main": "index.ts",
      "repository": "git+https://github.com/Open-Attestation/document-store.git",
      "license": "Apache-2.0",
      "publishConfig": {
        "access": "public"
      }
    }
EOF

  jq --arg target "$target" '.name = "@govtechsg/document-store-\($target)"' package.json > package.json.tmp && mv package.json.tmp package.json

  cp ../../README.md .

  sed -e 's|<p align="center">Document Store</p>|<p align="center">Document Store ('"$target"')</p>|' README.md > README.md.tmp && mv README.md.tmp README.md

  npm install "@typechain/$target" --save-dev --no-fund --no-audit

  npx typechain --target $target --out-dir . '../../artifacts/src/**/*[^dbg].json'

  echo "✅ Completed building types for $target!"
}

publish_types() {
  cd $workdir

  local version="$1"
  echo "Publish version: $version"

  for folder in "$workdir"/.build/*; do
    if [ -d "$folder" ]; then
      # Unlikely, but skip if it is not folder
      cd "$folder" || continue

      jq ".version = \"$version\"" package.json > package.json.tmp && mv package.json.tmp package.json

      echo "Updated $(basename "$folder") package.json to version $version."
      echo "📢 Publishing $(basename "$folder") package to NPM..."

      npm publish

      echo "🎉 Completed publishing $(basename "$folder") to NPM as $version!"
    fi
  done
}

if [ "$#" -ne 2 ]; then
    echo "Invalid number of arguments. Usage: build.sh {typechain|publish} target|version"
    exit 1
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "All arguments are required. Usage: build.sh {typechain|publish} target|version"
    exit 1
fi

case "$1" in
    "typechain")
        build_types "$2"
        ;;
    "publish")
        publish_types "$2"
        ;;
    *)
        echo "Invalid command. Usage: build.sh {typechain|publish} target|version"
        exit 1
        ;;
esac
