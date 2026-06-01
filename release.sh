#!/bin/bash

set -euo pipefail

NEW_VERSION=${1:-not provided}
MINIMUM_OBSIDIAN_VERSION=${2:-not provided}

if [ -f "$(dirname "$0")/version_info.sh" ]; then
  echo "Gathering version information for release..."
  bash "$(dirname "$0")/version_info.sh" "${NEW_VERSION}" "${MINIMUM_OBSIDIAN_VERSION}"
  echo ""
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "main" ]]; then
  echo "Error: You are not on the 'main' branch. Current branch: '$current_branch'"
  echo "Please switch to the 'main' branch to run this release."
  echo "Exiting."

  exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Must provide exactly two arguments."
    echo "First one must be the new version number."
    echo "Second one must be the minimum obsidian version for this release."
    echo ""
    echo "Example usage:"
    echo "release.sh 0.3.0 0.11.13"
    echo "Exiting."

    exit 1
fi

PACKAGE_JSON="package.json" #required
MANIFEST_JSON="manifest.json" #required
VERSIONS_JSON="versions.json" #required
PACKAGE_LOCK_JSON="package-lock.json" # not required, auto-generated / overridden by npm install

if [ ! -f "$PACKAGE_JSON" ] || [ ! -f "$MANIFEST_JSON" ] || [ ! -f "$VERSIONS_JSON" ]; then
  echo "Error: One or more required files are missing."
  echo "       Make sure you are running this script from the root of the repository and that the following files exist:"
  echo "       $PACKAGE_JSON, $MANIFEST_JSON, $VERSIONS_JSON"
  echo "Exiting."

  exit 1
fi

if [[ $(git status --porcelain) == " M ${PACKAGE_LOCK_JSON}" ]]; then
  echo "Info: ${PACKAGE_LOCK_JSON} has unstaged changes. Will be recreated with new version and committed."
  echo "Continuing."
elif [[ $(git status --porcelain) ]]; then
  echo "Changes in the git repo."
  echo "Exiting."

  exit 1
fi

if git rev-parse "$NEW_VERSION" >/dev/null 2>&1; then
  echo "Error: Tag '$NEW_VERSION' already exists."
  echo "Exiting."

  exit 1
fi

echo "Updating to version ${NEW_VERSION} with minimum obsidian version ${MINIMUM_OBSIDIAN_VERSION}"

read -p "Continue? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Updating ${PACKAGE_JSON}"
  node -e "const fs=require('fs'); const p='${PACKAGE_JSON}'; const j=JSON.parse(fs.readFileSync(p,'utf8')); j.version='${NEW_VERSION}'; fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n');"

  echo "Updating ${MANIFEST_JSON}"
  node -e "const fs=require('fs'); const p='${MANIFEST_JSON}'; const j=JSON.parse(fs.readFileSync(p,'utf8')); j.version='${NEW_VERSION}'; j.minAppVersion='${MINIMUM_OBSIDIAN_VERSION}'; fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n');"

  echo "Updating ${VERSIONS_JSON}"
  node -e "const fs=require('fs'); const p='${VERSIONS_JSON}'; const j=JSON.parse(fs.readFileSync(p,'utf8')); const k={ '${NEW_VERSION}': '${MINIMUM_OBSIDIAN_VERSION}'}; fs.writeFileSync(p,JSON.stringify({...k, ...j},null,2)+'\n');"

  echo "Running npm in case node_modules is out-of-date"
  echo "This will also update ${PACKAGE_LOCK_JSON} with the new version number, which will be committed."
  npm install

  read -p "Create git commit, tag, and push? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    git add -A .
    git commit -m"Update to version ${NEW_VERSION}"
    git tag "${NEW_VERSION}"
    git push
    LEFTHOOK=0 git push --tags
  fi

else
  echo "Exiting."
  exit 1
fi