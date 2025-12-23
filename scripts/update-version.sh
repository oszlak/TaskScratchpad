#!/bin/bash
# Updates version in Swift files
# Usage: ./update-version.sh 1.2.3

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

echo "Updating version to $VERSION..."

# Update Version.swift
sed -i '' "s/public static let version = \".*\"/public static let version = \"$VERSION\"/" Sources/TaskScratchpadCore/Version.swift

# Update create-dmg.sh
sed -i '' "s/VERSION=\".*\"/VERSION=\"$VERSION\"/" scripts/create-dmg.sh

echo "Version updated to $VERSION"

