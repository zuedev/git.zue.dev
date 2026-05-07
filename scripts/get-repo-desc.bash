#!/bin/bash

LOCK_FILE=/var/lock/get-repo-desc.lock

exec 9>"$LOCK_FILE"
if ! flock --nonblock 9; then
  echo "Another instance is already running. Exiting."
  exit 1
fi

for repository in /repositories/*; do
  echo "Processing repository: $(basename "$repository")"

  cd /repositories/$(basename "$repository")

  gitinfoExists=$(git ls-tree HEAD -- .gitinfo 2>/dev/null)

  echo "gitinfoExists: $gitinfoExists"

  # does gitinfo exist?
  if [ -z "$gitinfoExists" ]; then
    echo "No .gitinfo found for $(basename "$repository"). Blanking description."
    echo "" > /repositories/$(basename "$repository")/description
    continue
  fi

  gitinfoContents=$(git cat-file -p @:.gitinfo)

  echo "gitinfoContents: $gitinfoContents"

  # extract description from gitinfo (json format)
  description=$(echo "$gitinfoContents" | grep -oP '"description":\s*"\K[^"]+')

  echo "Extracted description: $description"

  # write description to repository description file
  echo "$description" > /repositories/$(basename "$repository")/description
done