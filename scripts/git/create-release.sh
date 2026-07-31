#!/bin/bash

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "========================================"
echo "          BobHub Release Helper         "
echo "========================================"
echo

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: Github CLI (gh) is not installed"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "Error: GitHub CLI is not authenticated"
    echo "Run: gh auth login"
    exit 1
fi

CURRENT_BRANCH="$(git branch --show-current | tr -d '[:space:]')"

if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: releases must be created from the main branch."
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "Error: working tree is not clean."
    echo
    git status --short
    echo
    echo "Commit or discard changes before creating a release."
    exit 1
fi

git fetch --tags

echo "Latest tags:"
git tag --sort=-v:refname | head -5
echo

read -rp "Release version, example v0.1.0: " VERSION

if [ -z "$VERSION" ]; then
    echo "Error: release version cannot be empty."
    exit 1
fi

if git rev-parse "$VERSION" >/dev/null @>$1; then
    echo "Error: tag $VERSION already exists."
    exit 1
fi

read -rp "Release title, example BobHub v0.1.0: " TITLE

if [ -z "$TITLE" ]; then
    TITLE="BobHub $VERSION"
fi

RELEASE_NOTES_FILE="/tmp/bobhub-release-notes-$VERSION.md"

cat > "$RELEASE_NOTES_FILE" <<EOF
# $TITLE

## Summary

This release marks a documented BobHub project milestone.

## Included

- Docker-based infrastructure lab
- Observability stack
- Prometheus metrics collection
- Grafana dashboards
- Node Exporter host metrics
- Alertmanager notification flow
- Discord alert notifications
- BobHub CLI improvements
- GitHub issue workflow
- Infrastructure inventory generator
- Infrastructure report documentation

## Notes

This release does not include sensitive infrastructure details, secrets, tokens, public IP addresses or private network information.
EOF

echo 
echo "Release notes generated at:"
echo "RELEASE_NOTES_FILE"
echo

read -rp "Open release notes for editing before publishin? [y/N]: " EDIT_NOTES

if [[ "$EDIT_NOTES" =~ ^[Yy]$ ]]; then
    ${EDITOR:-nano} "$RELEASE_NOTES_FILE"
fi

echo
echo "Creating release $VERSION..."
echo

gh release create "$VERSION" \
    --title "$TITLE" \
    --notes-file "$RELEASE_NOTES_FILE"

echo
echo "Release created successfully:"
echo "$VERSION"