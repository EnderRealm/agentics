#!/usr/bin/env bash
set -euo pipefail

VERSION=16

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

SCRIPT_REPO="https://raw.githubusercontent.com/EnderRealm/agentics/main/scripts/init-project.sh"

usage() {
    cat <<EOF
init-project v${VERSION}

Usage: $(basename "$0") <project-name> [options]

Options:
    --private       Create private GitHub repo (default: public)
    --org NAME      Create repo under organization (skips prompt)
    --no-push       Skip GitHub repo creation and push
    --no-update     Skip auto-update check
    --description   Repository description
    -h, --help      Show this help

Examples:
    $(basename "$0") my-project
    $(basename "$0") my-project --private --description "My awesome project"
    $(basename "$0") my-project --org MyCompany
EOF
    exit 0
}

auto_update() {
    local tmp remote_version
    tmp=$(mktemp)

    if curl -fsSL "$SCRIPT_REPO" -o "$tmp" 2>/dev/null; then
        if [[ -s "$tmp" ]]; then
            remote_version=$(grep -m1 '^VERSION=' "$tmp" | cut -d= -f2)

            if [[ -n "$remote_version" ]] && [[ "$remote_version" -gt "$VERSION" ]]; then
                warn "Updating v${VERSION} → v${remote_version}..."
                mv "$tmp" "$0"
                chmod +x "$0"
                exec "$0" --no-update "$@"
            fi
        fi
    fi
    rm -f "$tmp" 2>/dev/null
}

# Defaults
PRIVATE=false
NO_PUSH=false
NO_UPDATE=false
DESCRIPTION=""
ORG=""
ORIGINAL_ARGS=("$@")

# Parse args
[[ $# -eq 0 ]] && usage
PROJECT_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --private) PRIVATE=true; shift ;;
        --no-push) NO_PUSH=true; shift ;;
        --no-update) NO_UPDATE=true; shift ;;
        --org) ORG="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        -h|--help) usage ;;
        -*) error "Unknown option: $1" ;;
        *) PROJECT_NAME="$1"; shift ;;
    esac
done

# Auto-update check
[[ "$NO_UPDATE" == false ]] && auto_update "${ORIGINAL_ARGS[@]}"

[[ -z "$PROJECT_NAME" ]] && error "Project name required"

# Validate project name
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Invalid project name. Use alphanumeric, hyphens, underscores only."
fi

# Check dependencies
check_deps() {
    local missing=()
    command -v git &>/dev/null || missing+=("git")
    command -v gh &>/dev/null || missing+=("gh (GitHub CLI)")

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
    fi

    if [[ "$NO_PUSH" == false ]]; then
        gh auth status &>/dev/null || error "GitHub CLI not authenticated. Run: gh auth login"
    fi
}

check_deps

# Create project directory
[[ -d "$PROJECT_NAME" ]] && error "Directory '$PROJECT_NAME' already exists"

info "init-project v${VERSION}"
info "Creating project: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize git
git init -q
log "Initialized git repository"

# Create .gitignore
cat > .gitignore <<'EOF'
# Beads (for when you add beads later)
.beads/beads.db
.beads/beads.db-*
.beads/*.sock
.beads/*.pipe
.beads/*.lock
.beads/daemon.log

# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db

# Editors
*.swp
*~
.idea/
.vscode/
EOF
log "Created .gitignore"

# Create .example.env
cat > .example.env <<'EOF'
# Copy to .env and fill in values
# cp .example.env .env

# ANTHROPIC_API_KEY=
# DATABASE_URL=
EOF
log "Created .example.env"

# Create CLAUDE.md
cat > CLAUDE.md <<'EOF'
# Claude Code Instructions

## Project Overview

<!-- Describe your project here -->

## Development Guidelines

<!-- Add your coding standards, architecture notes, etc. -->
EOF
log "Created CLAUDE.md"

# Create README.md
cat > README.md <<EOF
# $PROJECT_NAME

## Setup

\`\`\`bash
cp .example.env .env
# Edit .env with your values
\`\`\`

## Development

<!-- Add development instructions -->
EOF
log "Created README.md"

# GitHub repo creation
if [[ "$NO_PUSH" == false ]]; then
    info "Creating GitHub repository..."

    # Get user and orgs
    GH_USER=$(gh api user --jq '.login')

    if [[ -n "$ORG" ]]; then
        # Use provided org
        REPO_OWNER="$ORG"
    else
        ORGS=$(gh api user/orgs --jq '.[].login' 2>/dev/null || true)

        # Build options
        OPTIONS=("$GH_USER (personal)")
        while IFS= read -r org; do
            [[ -n "$org" ]] && OPTIONS+=("$org")
        done <<< "$ORGS"

        # Prompt if multiple options
        if [[ ${#OPTIONS[@]} -gt 1 ]]; then
            echo ""
            info "Select account/organization:"
            for i in "${!OPTIONS[@]}"; do
                echo "    $((i+1))) ${OPTIONS[$i]}"
            done
            echo ""
            read -rp "Choice [1]: " CHOICE
            CHOICE=${CHOICE:-1}

            if [[ "$CHOICE" -eq 1 ]]; then
                REPO_OWNER="$GH_USER"
            else
                REPO_OWNER="${OPTIONS[$((CHOICE-1))]}"
            fi
        else
            REPO_OWNER="$GH_USER"
        fi
    fi

    GH_ARGS=(create "${REPO_OWNER}/${PROJECT_NAME}" --source=. --remote=origin)
    [[ "$PRIVATE" == true ]] && GH_ARGS+=(--private) || GH_ARGS+=(--public)
    [[ -n "$DESCRIPTION" ]] && GH_ARGS+=(--description "$DESCRIPTION")

    gh repo "${GH_ARGS[@]}"

    # Force SSH remote
    git remote set-url origin "git@github.com:${REPO_OWNER}/${PROJECT_NAME}.git"
    log "Created GitHub repository (SSH)"
fi

# Initial commit
git add -A
git commit -q -m "Initial project setup"
log "Created initial commit"

# Push to GitHub
if [[ "$NO_PUSH" == false ]]; then
    git push -u origin main -q
    log "Pushed to GitHub"
fi

echo ""
log "Project '$PROJECT_NAME' initialized successfully!"
info "Next steps:"
echo "    cd $PROJECT_NAME"
echo ""
echo "    # To add Beads issue tracking:"
echo "    bd init"
echo "    bd migrate sync beads-sync"
echo "    bd hooks install"
echo "    bd daemon start --auto-commit --auto-push"
