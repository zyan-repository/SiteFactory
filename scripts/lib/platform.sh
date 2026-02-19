#!/usr/bin/env bash
# platform.sh - Cross-platform compatibility helpers.
# Provides portable sed, Hugo resolution, and OS-aware install suggestions.
# Usage: source scripts/lib/platform.sh

# Portable in-place sed that works on both macOS (BSD sed) and Linux (GNU sed).
# Usage: sed_inplace <sed-args...> <file>
# Supports all sed flags including multiple -e expressions.
sed_inplace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Resolve the Hugo binary. Prints path if found, empty string if not.
# Usage: HUGO_CMD=$(find_hugo)
find_hugo() {
  command -v hugo 2>/dev/null || echo ""
}

# Return a platform-appropriate install suggestion for a tool.
# Usage: suggest_install "hugo" "hugo"
#   $1 = display name, $2 = package name (optional, defaults to $1)
suggest_install() {
  local tool_name="$1"
  local pkg_name="${2:-$1}"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "$tool_name (brew install $pkg_name)"
  elif command -v apt-get &>/dev/null; then
    echo "$tool_name (sudo apt-get install $pkg_name)"
  elif command -v dnf &>/dev/null; then
    echo "$tool_name (sudo dnf install $pkg_name)"
  elif command -v pacman &>/dev/null; then
    echo "$tool_name (sudo pacman -S $pkg_name)"
  else
    echo "$tool_name (install via your system package manager)"
  fi
}
