#!/bin/bash

# This script pushes the repository mirrors to their respective remote URLs if they are defined in the .gitinfo file.

LOCK_FILE=/var/lock/push-repo-mirrors.lock

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

        # Update the GitHub repo's default branch to match the local HEAD before mirroring,
        # so that --mirror can delete any branch that was previously the default.
        local_default=$(git symbolic-ref --short HEAD 2>/dev/null)
        github_repo="${mirror#https://github.com/}"
        if [ -n "$local_default" ]; then
          echo "Setting GitHub default branch to '$local_default' for $github_repo"
          curl -sf -X PATCH \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            -d "{\"default_branch\":\"$local_default\"}" \
            "https://api.github.com/repos/$github_repo" > /dev/null \
            || echo "Warning: failed to update default branch on GitHub for $github_repo"
        fi

        echo "Pushing to GitHub mirror: $mirror"
        git push --mirror "https://x-access-token:$GITHUB_TOKEN@$mirror_host" 2>&1 | sed "s/$GITHUB_TOKEN/[REDACTED]/g" || echo "Failed to push to $mirror"
        ;;
      *)
        echo "Unknown mirror type: $mirror. Skipping."
        ;;
    esac
  done <<< "$mirrors"
done