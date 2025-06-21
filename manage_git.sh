#!/usr/bin/env bash
set -euo pipefail

# Name of this script (for usage)
SCRIPT_NAME=$(basename "$0")

# Usage function
usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [push|pull] [all|lab|hub]
  $SCRIPT_NAME addRepo <github-repo-url>

  push|pull      Aktion: push = Branch zum Remote pushen, pull = Branch vom Remote holen
  all            auf beide Remotes anwenden (origin + github)
  lab            nur GitLab (origin)
  hub            nur GitHub (github)
  addRepo        fügt das Remote 'github' hinzu; erwartet eine Repository-URL

EOF
}

# Check at least one argument is provided
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

ACTION=$1
TARGET=${2:-}

# → New command: addRepo
if [[ "$ACTION" == "addRepo" ]]; then
  if [[ -z "$TARGET" ]]; then
    echo "Error: Keine URL angegeben für addRepo."
    usage
    exit 1
  fi
  echo "→ git remote add github $TARGET"
  git remote add github "$TARGET"
  echo "Remote 'github' wurde hinzugefügt: $TARGET"
  exit 0
fi

# Only push|pull allowed (otherwise show usage)
case "$ACTION" in
  push|pull) ;;
  *)
    echo "Error: Unbekannte Aktion '$ACTION'."
    usage
    exit 1
    ;;
esac

# Determine current branch
BRANCH=$(git symbolic-ref --short HEAD)

# Function to perform the action on a remote
do_action() {
  local remote=$1
  echo "→ git $ACTION $remote $BRANCH"
  git "$ACTION" "$remote" "$BRANCH"
}

# Evaluate target remotes
case "$TARGET" in
  all)
    do_action origin
    do_action github
    ;;
  lab)
    do_action origin
    ;;
  hub)
    do_action github
    ;;
  *)
    echo "Error: Unbekanntes Ziel '$TARGET'."
    usage
    exit 1
    ;;
esac

echo "Done."
