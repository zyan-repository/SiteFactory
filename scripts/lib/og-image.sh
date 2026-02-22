#!/usr/bin/env bash
# og-image.sh - Generate branded OG images using ImageMagick.
# Falls back to copying a generic placeholder if ImageMagick is not installed.
#
# Usage:
#   source scripts/lib/og-image.sh
#   generate_og_image "Site Title" "/path/to/output.png" "#0066cc"

# Generate a 1200x630 OG image with gradient background and centered text.
# Args:
#   $1 - Title text to display
#   $2 - Output file path (PNG)
#   $3 - Primary color (optional, default #0066cc)
generate_og_image() {
  local title="$1"
  local output="$2"
  local color="${3:-#0066cc}"

  # Derive a darker shade for gradient endpoint
  local dark_color="#001a33"

  if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
    # No ImageMagick — try fallback
    local fallback="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/themes/sitefactory/static/og-default.png"
    if [[ -f "$fallback" ]]; then
      cp "$fallback" "$output"
      return 0
    fi
    return 1
  fi

  # Use magick (ImageMagick 7) or convert (ImageMagick 6)
  local cmd="convert"
  if command -v magick &>/dev/null; then
    cmd="magick"
  fi

  # Create gradient background with centered title
  if ! $cmd -size 1200x630 \
    "gradient:${color}-${dark_color}" \
    -gravity center \
    -pointsize 64 \
    -fill white \
    -font "Helvetica-Bold" \
    -annotate 0 "$title" \
    "$output" 2>/dev/null; then
    # If font not found, try without specifying font
    $cmd -size 1200x630 \
      "gradient:${color}-${dark_color}" \
      -gravity center \
      -pointsize 64 \
      -fill white \
      -annotate 0 "$title" \
      "$output" 2>/dev/null || return 1
  fi

  return 0
}
