#!/bin/bash

# discover-tools.sh
# Script to discover all available tools in the openapi-servers repository
# Returns a JSON array of tool names that have Dockerfiles

set -euo pipefail

REPO_URL=${1:-"https://github.com/open-webui/openapi-servers"}
SERVERS_DIR="servers"
TEMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "🔍 Discovering tools in $REPO_URL..." >&2

# Clone the repository (shallow clone for speed)
git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" >&2

# Find all directories in servers/ that contain a Dockerfile
tools=()
if [ -d "$TEMP_DIR/repo/$SERVERS_DIR" ]; then
  while IFS= read -r -d '' dir; do
    tool_name=$(basename "$dir")
    if [ -f "$dir/Dockerfile" ]; then
      tools+=("$tool_name")
      echo "✅ Found tool: $tool_name" >&2
    else
      echo "⚠️  Skipping $tool_name (no Dockerfile)" >&2
    fi
  done < <(find "$TEMP_DIR/repo/$SERVERS_DIR" -maxdepth 1 -type d -not -path "$TEMP_DIR/repo/$SERVERS_DIR" -print0)
else
  echo "❌ Error: $SERVERS_DIR directory not found in repository" >&2
  exit 1
fi

# Output as JSON array for GitHub Actions
printf '%s\n' "${tools[@]}" | jq -R -s -c 'split("\n")[:-1]'
