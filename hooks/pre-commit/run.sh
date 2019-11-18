#!/bin/bash

echo "running swift format..."
CONFIG_PATH=".swiftformat"
CHANGED_FILES="$(git diff-index --no-commit-id --name-only --cached -r HEAD | grep -e '\(.*\).swift$')"
SWIFT_FORMAT="./Example/Pods/SwiftFormat/CommandLineTool/swiftformat"

if [ "$CHANGED_FILES" != "" ]; then
    git diff --diff-filter=d --staged --name-only | grep -e '\(.*\).swift$' | while read line; do
        $SWIFT_FORMAT --config $CONFIG_PATH "$line";
        git add "$line";
    done
fi