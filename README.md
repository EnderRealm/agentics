# agentics

Project scaffolding for GitHub + Beads + Claude Code workflows.

## Installation

One-liner install to `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/EnderRealm/agentics/main/scripts/install.sh | bash
```

Install to `/usr/local/bin` (requires sudo):

```bash
curl -fsSL https://raw.githubusercontent.com/EnderRealm/agentics/main/scripts/install.sh | bash -s -- --system
```

Custom directory:

```bash
curl -fsSL https://raw.githubusercontent.com/EnderRealm/agentics/main/scripts/install.sh | bash -s -- --dir ~/bin
```

## Usage

```bash
init-project my-project
init-project my-project --private
init-project my-project --private --description "My awesome project"
init-project my-project --org MyCompany
```

### Options

| Flag | Description |
|------|-------------|
| `--private` | Create private GitHub repo (default: public) |
| `--org NAME` | Create repo under organization |
| `--no-push` | Skip GitHub repo creation and push |
| `--description` | Repository description |

## What it creates

- Git repository with `.gitignore`
- GitHub remote (SSH)
- Beads issue tracker
- `CLAUDE.md` for Claude Code instructions
- `.example.env` template

## Requirements

- [git](https://git-scm.com/)
- [gh](https://cli.github.com/) (GitHub CLI, authenticated)
- [bd](https://github.com/beads-project/beads) (Beads CLI)

## Auto-update

The script checks for updates on each run and self-updates when a new version is available.
