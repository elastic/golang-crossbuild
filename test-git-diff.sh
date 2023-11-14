#!/usr/bin/env bash

git_diff() {
  patterns=$1
  patterns_formatted="$(echo "$patterns" | tr ':' '\n')"

  echo "Found files changed for $patterns:"
  if git diff --name-only HEAD@{1} HEAD | grep -qE -e "$patterns_formatted"; then
    echo true
  else
    echo false
  fi
}
