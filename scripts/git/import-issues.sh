#!/usr/bin/env bash

set -euo pipefail

FILE="${1:-templates/issues.yaml}"

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is not installed."
    exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
    echo "Error: yq is not installed."
    echo "Install with:"
    echo "sudo snap install yq"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: file not found $FILE"
    exit 1
fi

COUNT=$(yq e '.issues | length' "$FILE")

echo "Importing $COUNT GitHub issues from $FILE"
echo

for i in $(seq 0 $((COUNT - 1))); do
    TITLE=$(yq -r ".issues[$i].title" "$FILE")
    BODY=$(yq -r ".issues[$i].body" "$FILE")
    LABELS=$(yq -r ".issues[$i].labels // [] | join(\",\")" "$FILE")

    echo "Creating issue: $TITLE"
    
    if [ -n "$LABELS" ] && [ "$LABELS" != "null" ] && [ "$LABELS" != " " ]; then
        gh issue create \
          --title "$TITLE" \
          --body "$BODY" \
          --label "$LABELS"
    else
        gh issue create \ 
          --title "$TITLE" \  
          --body "$BODY"
    fi 

    echo
done

echo "Done."