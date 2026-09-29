#!/bin/bash
# novelution-new-repo.sh: create a new Novelution repository with the
# standard starter files, make the first commit on main, and optionally
# create the GitHub remote and push.
#
# Usage: ./novelution-new-repo.sh <repo-name> [options]
# Run with --help for the full option list.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: novelution-new-repo.sh <repo-name> [options]

Creates <repo-name>/ with Novelution's standard starter files and an
initial commit on main. Nothing is sent to GitHub unless --remote is set.

Options:
  -m, --module <name>       Product area the repo belongs to:
                              proposals, awards, coi, irb, iacuc, ibc,
                              research-security, animal-care, platform
                            (default: platform)
  -d, --description <text>  One-line description for the README and GitHub
  -o, --org <org>           GitHub organization for --remote
                            (default: $NOVELUTION_GITHUB_ORG, else your
                            personal account)
  -p, --path <dir>          Parent directory for the new repo (default: .)
      --public              Make the GitHub repo public (default: private)
      --remote              Create the GitHub repo and push main
                            (uses the gh CLI, or GITHUB_TOKEN with curl)
  -n, --dry-run             Show what would be created, then stop
  -h, --help                Show this help

Examples:
  ./novelution-new-repo.sh irb-reports-wrapper -m irb -d "IRB reporting wrapper"
  ./novelution-new-repo.sh coi-disclosure-api -m coi -o novelution --remote
EOF
}

die() {
  echo "novelution-new-repo: $*" >&2
  exit 1
}

need_value() {
  [ $# -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"
}

# Escape a string for use inside a JSON string literal.
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

NAME=""
MODULE="platform"
DESCRIPTION=""
ORG="${NOVELUTION_GITHUB_ORG:-}"
PARENT="."
VISIBILITY="private"
REMOTE=false
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--module)      need_value "$@"; MODULE=$2; shift 2 ;;
    -d|--description) need_value "$@"; DESCRIPTION=$2; shift 2 ;;
    -o|--org)         need_value "$@"; ORG=$2; shift 2 ;;
    -p|--path)        need_value "$@"; PARENT=$2; shift 2 ;;
    --public)         VISIBILITY="public"; shift ;;
    --remote)         REMOTE=true; shift ;;
    -n|--dry-run)     DRY_RUN=true; shift ;;
    -h|--help)        usage; exit 0 ;;
    -*)               die "unknown option '$1' (see --help)" ;;
    *)
      [ -z "$NAME" ] || die "only one repo name is allowed (got '$NAME' and '$1')"
      NAME=$1; shift ;;
  esac
done

# --- Validate inputs before touching the filesystem ---

[ -n "$NAME" ] || { usage >&2; exit 1; }
[[ $NAME =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
  die "repo name must be lowercase kebab-case, e.g. irb-reports-wrapper"

case "$MODULE" in
  proposals)         MODULE_LABEL="Proposals" ;;
  awards)            MODULE_LABEL="Awards" ;;
  coi)               MODULE_LABEL="Conflict of Interest (COI)" ;;
  irb)               MODULE_LABEL="IRB (human subjects research)" ;;
  iacuc)             MODULE_LABEL="IACUC (animal care and use protocols)" ;;
  ibc)               MODULE_LABEL="IBC (biosafety)" ;;
  research-security) MODULE_LABEL="Research Security" ;;
  animal-care)       MODULE_LABEL="Animal Care (procurement, inventory, billing, veterinary care)" ;;
  platform)          MODULE_LABEL="Shared platform" ;;
  *)                 die "unknown module '$MODULE' (see --help)" ;;
esac

DESCRIPTION=${DESCRIPTION:-"Novelution $MODULE_LABEL repository."}
TARGET="$PARENT/$NAME"

[ -d "$PARENT" ] || die "parent directory '$PARENT' does not exist"
[ ! -e "$TARGET" ] || die "'$TARGET' already exists"
git config user.name >/dev/null && git config user.email >/dev/null ||
  die "set git user.name and user.email before creating a repo"

if $REMOTE && ! command -v gh >/dev/null 2>&1 && [ -z "${GITHUB_TOKEN:-}" ]; then
  die "--remote needs the gh CLI (logged in) or a GITHUB_TOKEN environment variable"
fi

if $DRY_RUN; then
  echo "Would create $TARGET"
  echo "  module:      $MODULE_LABEL"
  echo "  description: $DESCRIPTION"
  echo "  files:       README.md CHANGELOG.md .gitignore .editorconfig"
  echo "               .github/pull_request_template.md"
  echo "  branch:      main, with one initial commit"
  if $REMOTE; then
    echo "  remote:      github.com/${ORG:-<your account>}/$NAME ($VISIBILITY), push main"
  else
    echo "  remote:      none (add --remote to create it on GitHub)"
  fi
  exit 0
fi

# --- Scaffold the working tree ---

mkdir -p "$TARGET/.github"

cat > "$TARGET/README.md" <<EOF
# $NAME

$DESCRIPTION

- **Product area:** $MODULE_LABEL
- **Created:** $(date +%Y-%m-%d)

## Getting started

Add setup, build, and test instructions here as the project takes shape.

## Data handling

This repository must never contain client data, PHI, protocol documents,
or credentials. Use synthetic or de-identified fixtures for tests, and keep
secrets in environment variables or the team's secret store.
EOF

cat > "$TARGET/CHANGELOG.md" <<'EOF'
# Changelog

All notable changes to this repository are recorded here.

## Unreleased

- Initial repository created with novelution-new-repo.sh.
EOF

cat > "$TARGET/.gitignore" <<'EOF'
# OS and editor files
.DS_Store
Thumbs.db
*~
*.swp
.idea/
.vscode/

# Dependencies and build output
node_modules/
dist/
build/
*.log

# Local configuration and secrets
.env
.env.*
!.env.example
*.pem
*.key
EOF

cat > "$TARGET/.editorconfig" <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
EOF

cat > "$TARGET/.github/pull_request_template.md" <<'EOF'
## Summary

What does this change do, and why?

## Testing

How was this verified?

## Checklist

- [ ] No client data, PHI, or credentials are included
- [ ] CHANGELOG.md is updated
- [ ] Documentation is updated if behavior changed
EOF

cd "$TARGET"
git init -q
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -q -m "Initial commit for $NAME ($MODULE)"
echo "Created $TARGET with an initial commit on main."

# --- Optionally create the GitHub repo and push ---

if $REMOTE; then
  if command -v gh >/dev/null 2>&1; then
    gh repo create "${ORG:+$ORG/}$NAME" "--$VISIBILITY" \
      --description "$DESCRIPTION" --source . --remote origin --push
  else
    endpoint="https://api.github.com/user/repos"
    [ -z "$ORG" ] || endpoint="https://api.github.com/orgs/$ORG/repos"
    private=true
    [ "$VISIBILITY" = private ] || private=false
    response=$(curl -fsS -X POST "$endpoint" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -d "{\"name\":\"$NAME\",\"description\":\"$(json_escape "$DESCRIPTION")\",\"private\":$private}") ||
      die "GitHub API request failed (does $NAME already exist, and can the token create repos there?)"
    clone_url=$(printf '%s\n' "$response" | grep -o '"clone_url": *"[^"]*"' | head -n 1 |
      sed 's/.*"\([^"]*\)"$/\1/')
    [ -n "$clone_url" ] || die "GitHub did not return a clone URL"
    git remote add origin "$clone_url"
    git push -q -u origin main
  fi
  echo "Pushed main to GitHub (${ORG:-your account}/$NAME, $VISIBILITY)."
else
  echo "No remote created. Rerun with --remote, or add one yourself:"
  echo "  cd $TARGET && git remote add origin <url> && git push -u origin main"
fi
