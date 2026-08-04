#!/bin/sh
#
# Install the versioned git hooks (.githooks/) for the super-repo and every
# submodule that ships one. core.hooksPath is per-clone local config and is not
# itself versioned, so this must be run once per fresh clone (and again after a
# submodule first gains a .githooks/ directory).
#
#   ./scripts/install-hooks.sh
#
set -eu
cd "$(git rev-parse --show-toplevel)"

set_hooks() {
  if [ -d "$1/.githooks" ]; then
    git -C "$1" config core.hooksPath .githooks
    echo "hooks installed > $1"
  fi
}

set_hooks .
git submodule --quiet foreach 'echo "$sm_path"' | while read -r sm; do
  set_hooks "$sm"
done
