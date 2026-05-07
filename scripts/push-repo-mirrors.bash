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
  mirrors=$(echo "$gitinfoContents" | grep -oP '"mirrors":\s*\[\K[^\]]+')

  echo "Extracted mirrors: $mirrors"

  # push to each mirror
  for mirror in $(echo "$mirrors" | tr ',' '\n'); do
    case "$mirror" in
      *github.com*)
        # do we have a /run/secrets/github_token defined?
        if [ ! -f /run/secrets/github_token ]; then
          echo "/run/secrets/github_token not found. Skipping push to $mirror."
          continue
        fi

        GITHUB_TOKEN=$(cat /run/secrets/github_token)

        echo "Pushing to GitHub mirror: $mirror"
        git push --mirror "https://x-access-token:$GITHUB_TOKEN@$mirror" || echo "Failed to push to $mirror"
        ;;
      *)
        echo "Unknown mirror type: $mirror. Skipping."
        ;;
    esac
  done
done