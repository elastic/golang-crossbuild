#!/usr/bin/env bash
# shellcheck disable=SC2218 # false positive: file_at_ref is defined above its callers
# Helpers shared by bump-npcap-backports.sh and test-npcap-lib.sh. Source it,
# do not run it.
#
# Required environment:
#   GITHUB_TOKEN (read by the gh CLI)
#   docker login to docker.elastic.co, for npcap_image_exists

CROSSBUILD_REPO="${CROSSBUILD_REPO:-elastic/golang-crossbuild}"
NPCAP_IMAGE_REPO="docker.elastic.co/observability-ci/golang-crossbuild"
# Beats checks for the debian9 image of a Go version before it bumps npcap.
NPCAP_IMAGE_SUFFIX="debian9"

# Prints the raw content of <path> in <repo> at <ref>.
file_at_ref() { # <repo> <path> <ref>
  gh api -H "Accept: application/vnd.github.raw" "repos/$1/contents/$2?ref=$3"
}

# Returns 0 if <branch> exists in ${CROSSBUILD_REPO}, 1 if it does not, and
# exits on any other API error so a transient failure is not mistaken for
# "missing".
branch_exists() { # <branch>
  local output
  if output=$(gh api "repos/${CROSSBUILD_REPO}/branches/$1" 2>&1); then
    return 0
  fi
  case "$output" in
    *"HTTP 404"*) return 1 ;;
    *) echo "ERROR: cannot check branch $1: ${output}" >&2; exit 1 ;;
  esac
}

npcap_version_at() { # <ref>
  file_at_ref "$CROSSBUILD_REPO" Makefile.common "$1" | sed -n 's/^NPCAP_VERSION := //p'
}

go_version_at() { # <repo> <ref>
  file_at_ref "$1" .go-version "$2" | tr -d '[:space:]'
}

# Returns 0 if the image of <go_version> with npcap <npcap_version> is
# published, 1 if it is not, and exits on any other error (for example a
# failed login) so it is not mistaken for "missing".
npcap_image_exists() { # <go_version> <npcap_version>
  local image="${NPCAP_IMAGE_REPO}:$1-npcap-$2-${NPCAP_IMAGE_SUFFIX}"
  local output
  if output=$(docker manifest inspect "$image" 2>&1); then
    return 0
  fi
  case "$output" in
    *"no such manifest"*|*"manifest unknown"*|*"not found"*) return 1 ;;
    *) echo "ERROR: cannot check image ${image}: ${output}" >&2; exit 1 ;;
  esac
}
