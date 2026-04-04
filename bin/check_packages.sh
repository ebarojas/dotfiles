#!/bin/bash
#
# check_packages.sh — Check which packages in packages.txt exist in Debian repos
#
# Made to be run on MacOS AND test for debian repos
# Queries the Debian package API remotely, so works on any machine (macOS, Linux, etc.)
# without needing apt installed locally.
#
# Usage:
#   ./check_packages.sh [packages_file] [suite]
#
# Arguments:
#   packages_file   Path to packages file (default: ../packages.txt relative to this script)
#   suite           Debian suite to check against (default: trixie)
#
# Output:
#   Prints "Line N: <package>" for each package not found in the given suite.
#
# Notes:
#   - Requires curl
#   - Skips blank lines and comment lines (starting with #)
#   - Strips inline comments before checking
#   - Uses packages.debian.org to check binary package names directly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${1:-$SCRIPT_DIR/../packages.txt}"
SUITE="${2:-trixie}"

if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "Error: packages file not found: $PACKAGES_FILE" >&2
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "Error: curl is required" >&2
    exit 1
fi

GREEN='\033[0;32m'
NC='\033[0m'

check_pkg() {
    local pkg="$1"
    curl -fsSL "https://packages.debian.org/${SUITE}/${pkg}" 2>/dev/null \
        | grep -q "Package: ${pkg}"
}

lineno=0
total=0
found=0
while IFS= read -r line || [[ -n "$line" ]]; do
    ((lineno++))
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    pkg="${line%%#*}"
    pkg="${pkg%% }"
    [[ -z "$pkg" ]] && continue

    ((total++))
    if check_pkg "$pkg"; then
        ((found++))
    else
        echo "Line $lineno: $pkg"
    fi
done < "$PACKAGES_FILE"

echo -e "\n${GREEN}${found}/${total} packages found in Debian ${SUITE}${NC}"
