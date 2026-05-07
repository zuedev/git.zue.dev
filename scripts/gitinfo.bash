#/bin/bash

for repository in /repositories/*; do
  cd /repositories/$(basename "$repository")
  gitinfoExists=$(git ls-tree HEAD -- .gitinfo 2>/dev/null)

  # does gitinfo exist?
  if [ -z "$gitinfoExists" ]; then
    echo "No .gitinfo found for $(basename "$repository"). Blanking description."
    echo "" > /repositories/$(basename "$repository")/description
    continue
  fi

  gitinfoContents=$(git cat-file -p @:.gitinfo)

  # extract description from gitinfo (json format)
  description=$(echo "$gitinfoContents" | grep -oP '"description":\s*"\K[^"]+')

  # write description to repository description file
  echo "$description" > /repositories/$(basename "$repository")/description
done