#/bin/bash

for repository in /repositories/*; do
  cd /repositories/$(basename "$repository")
  gitinfo=$(git cat-file -p @:.gitinfo)

  # does gitinfo exist? expect "fatal" if not
  if [[ $gitinfo == fatal* ]]; then
    echo "No .gitinfo found for $(basename "$repository"). Blanking description."
    echo "" > /repositories/$(basename "$repository")/description
    continue
  fi

  # extract description from gitinfo (json format)
  description=$(echo "$gitinfo" | grep -oP '"description":\s*"\K[^"]+')

  # write description to repository description file
  echo "$description" > /repositories/$(basename "$repository")/description
done