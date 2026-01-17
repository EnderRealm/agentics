#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/EnderRealm/agentics/main/scripts/init-project.sh"
DEFAULT_DIR="$HOME/.local/bin"
SYSTEM_DIR="/usr/local/bin"
SCRIPT_NAME="init-project"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }

usage() {
    cat <<EOF
Install init-project script

Usage: $(basename "$0") [options]

Options:
    --system    Install to ${SYSTEM_DIR} (requires sudo)
    --dir DIR   Install to custom directory
    -h, --help  Show this help

Default: installs to ${DEFAULT_DIR}
EOF
    exit 0
}

INSTALL_DIR="$DEFAULT_DIR"
USE_SUDO=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --system) INSTALL_DIR="$SYSTEM_DIR"; USE_SUDO=true; shift ;;
        --dir) INSTALL_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) error "Unknown option: $1" ;;
    esac
done

# Create directory if needed
if [[ ! -d "$INSTALL_DIR" ]]; then
    if [[ "$USE_SUDO" == true ]]; then
        sudo mkdir -p "$INSTALL_DIR"
    else
        mkdir -p "$INSTALL_DIR"
    fi
    log "Created $INSTALL_DIR"
fi

# Download and install
TARGET="${INSTALL_DIR}/${SCRIPT_NAME}"
if [[ "$USE_SUDO" == true ]]; then
    curl -fsSL "$REPO_URL" | sudo tee "$TARGET" > /dev/null
    sudo chmod 755 "$TARGET"
else
    curl -fsSL "$REPO_URL" -o "$TARGET"
    chmod 755 "$TARGET"
fi

log "Installed ${SCRIPT_NAME} to ${TARGET}"

# Check if in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    warn "$INSTALL_DIR is not in your PATH"
    echo ""
    echo "Add to your shell config:"
    echo "    export PATH=\"${INSTALL_DIR}:\$PATH\""
fi
