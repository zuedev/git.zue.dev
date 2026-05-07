#!/bin/bash

# This script pushes the repository mirrors to their respective remote URLs if they are defined in the .gitinfo file.

for repository in /repositories/*; do
  echo "Processing repository: $(basename "$repository")"

  cd /repositories/$(basename "$repository")

  gitinfoExists=$(git ls-tree HEAD -- .gitinfo 2>/dev/null)

  echo "gitinfoExists: $gitinfoExists"

  # does gitinfo exist?
  if [ -z "$gitinfoExists" ]; then
    echo "No .gitinfo found for $(basename "$repository"). Skipping."
    continue
  fi

  gitinfoContents=$(git cat-file -p @:.gitinfo)

  echo "gitinfoContents: $gitinfoContents"

  # extract mirrors from gitinfo (json format)
  mirrors=$(echo "$gitinfoContents" | jq -r '.mirrors[]')

  echo "Extracted mirrors: $mirrors"

  # push to each mirror
  while IFS= read -r mirror; do
    [ -z "$mirror" ] && continue
    case "$mirror" in
      *github.com*)
        # do we have a /run/secrets/github_token defined?
        if [ ! -f /run/secrets/github_token ]; then
          echo "/run/secrets/github_token not found. Skipping push to $mirror."
          continue
        fi

        GITHUB_TOKEN=$(cat /run/secrets/github_token)

        mirror_host="${mirror#https://}"
        echo "Pushing to GitHub mirror: $mirror"
        git push --mirror "https://x-access-token:$GITHUB_TOKEN@$mirror_host" || echo "Failed to push to $mirror"
        ;;
      *)
        echo "Unknown mirror type: $mirror. Skipping."
        ;;
    esac
  done <<< "$mirrors"
done