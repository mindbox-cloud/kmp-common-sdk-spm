#!/bin/bash

# Check if the parameter is provided
if [ $# -eq 0 ]; then
  echo "Please provide the release version number as a parameter."
  exit 1
fi

# Check if the version number matches the semver format
if ! [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
  echo "The release version number does not match the semver format (X.Y.Z or X.Y.Z-rc)."
  exit 1
fi

current_branch=$(git symbolic-ref --short HEAD)
echo "Currently on branch: $current_branch"

version=$1
podspec_file="MindboxCommon.podspec"

if [ ! -f "$podspec_file" ]; then
  echo "Error: $podspec_file not found."
  exit 1
fi

current_version=$(grep -E "^[[:space:]]*s\.version" "$podspec_file" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+(-rc)?")
echo "Current version in $podspec_file: ${current_version:-<none>}"

echo "'$podspec_file' before updating:"
grep "s.version" "$podspec_file"
grep "s.source" "$podspec_file"

# Detect OS and use proper sed syntax
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS (BSD sed)
  sed -i '' -E "s|^[[:space:]]*s\.version[[:space:]]*=.*|    s.version      = '$version'|" "$podspec_file"
  sed -i '' -E "s|^[[:space:]]*s\.source[[:space:]]*=.*|    s.source       = { :http => 'https://github.com/vailence/kmp-common-sdk/releases/download/$version/MindboxCommon.xcframework.zip' }|" "$podspec_file"
else
  # Linux (GNU sed)
  sed -i -E "s|^[[:space:]]*s\.version[[:space:]]*=.*|    s.version      = '$version'|" "$podspec_file"
  sed -i -E "s|^[[:space:]]*s\.source[[:space:]]*=.*|    s.source       = { :http => 'https://github.com/vailence/kmp-common-sdk/releases/download/$version/MindboxCommon.xcframework.zip' }|" "$podspec_file"
fi

echo "'$podspec_file' after updating:"
grep "s.version" "$podspec_file"
grep "s.source" "$podspec_file"

git add "$podspec_file"
git commit -m "Update MindboxCommon.podspec to version $version" || echo "No changes to commit"

echo "Pushing changes to branch: $current_branch"
if ! git push origin "$current_branch"; then
  echo "Failed to push changes to origin/$current_branch"
  exit 1
fi

echo "✅ Podspec version updated from $current_version to $version successfully."
