#!/usr/bin/env bash
# scaffold-project.sh — Bootstrap a new project with linting, testing, and formatting config
# Usage: scaffold-project.sh <language> [project-path]
# Languages: go, python, rust, typescript, bash, c++, swift

set -euo pipefail

TEMPLATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"
PROJECT_PATH="${2:-.}"
LANGUAGE="${1:?Usage: scaffold-project.sh <language> [project-path]}"

if [[ ! -d "$TEMPLATES_DIR/$LANGUAGE" ]]; then
  echo "ERROR: Unknown language '$LANGUAGE'"
  echo "Available: go, python, rust, typescript, bash, c++, swift"
  exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "ERROR: Project path does not exist: $PROJECT_PATH"
  exit 1
fi

cd "$PROJECT_PATH"

echo "Scaffolding $LANGUAGE project in $(pwd)"

# Copy template files
for file in "$TEMPLATES_DIR/$LANGUAGE"/{Makefile,.golangci.yml,.clang-format,.clang-tidy,.shellcheckrc,.pre-commit-config.yaml,pyproject.toml}; do
  if [[ -f "$file" ]]; then
    basename=$(basename "$file")
    target="$PROJECT_PATH/$basename"

    if [[ -f "$target" ]]; then
      echo "⚠ File already exists: $basename (skipping)"
    else
      cp "$file" "$target"
      echo "✓ Created $basename"
    fi
  fi
done

# Initialize git (if not already)
if [[ ! -d .git ]]; then
  echo "Initializing git repository..."
  git init
fi

# Install pre-commit hooks (if .pre-commit-config.yaml exists)
if [[ -f .pre-commit-config.yaml ]]; then
  echo "Installing pre-commit hooks..."
  pre-commit install || echo "⚠ pre-commit not installed. Run: pip install pre-commit && pre-commit install"
fi

echo ""
echo "✅ Scaffolding complete!"
echo ""
echo "Next steps:"
echo "1. Review and customize config files as needed"
echo "2. Run 'make help' to see available targets"
echo "3. Commit scaffolding files: git add . && git commit -m 'scaffold: add linting/testing config'"
