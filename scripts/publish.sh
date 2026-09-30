#!/usr/bin/env bash
# Publish the site to GitHub Pages without GitHub Actions.
#
# This script is the site's one publication adapter. It builds the committed tree and pushes the
# result to the `gh-pages` branch, which GitHub Pages serves (Settings > Pages: branch gh-pages,
# folder /). Nothing else deploys the site. Changing where the site is published means changing
# this file and nothing else.
#
#   bash scripts/publish.sh
#
# What it does, in order, stopping at the first failure:
#   1. refuses if the working tree has uncommitted or untracked changes;
#   2. refuses unless the running Node's major version is the one pinned in .nvmrc;
#   3. exports HEAD with `git archive` into a temporary directory and runs `npm ci` and
#      `npm run build` there, so only committed files can reach the site (the working copy
#      holds gitignored files, such as public/images/archive/, that must never be published);
#   4. adds an empty .nojekyll, so Pages serves the files as they are instead of running Jekyll;
#   5. commits the built files as a normal commit on top of gh-pages (an orphan commit the first
#      time the branch is created), never rewriting its history;
#   6. pushes gh-pages without --force, confirms the remote branch now points at that commit,
#      and prints it.
#
# A push that is rejected because gh-pages moved on the remote is the correct outcome: someone
# else published. Re-run the script to build on top of their commit.
set -euo pipefail

REMOTE=origin
BRANCH=gh-pages

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_DIR_ABS="$(git -C "$REPO" rev-parse --absolute-git-dir)"

die() { echo "publish: $*" >&2; exit 1; }

# 1. Clean tree.
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  git -C "$REPO" status --short >&2
  die "the working tree has uncommitted or untracked changes; commit or remove them first"
fi

# 2. Pinned Node.
[ -f "$REPO/.nvmrc" ] || die ".nvmrc is missing; it pins the Node major version the site builds with"
want="$(tr -d '[:space:]v' < "$REPO/.nvmrc")"
have="$(node -p 'process.versions.node')"
if [ "${have%%.*}" != "${want%%.*}" ]; then
  die "Node $have is running but .nvmrc pins Node $want; switch Node versions and re-run"
fi

src_sha="$(git -C "$REPO" rev-parse HEAD)"
src_ref="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 3. Build the committed tree.
mkdir "$work/src"
git -C "$REPO" archive --format=tar "$src_sha" | tar -x -C "$work/src"
echo "publish: building $src_ref@${src_sha:0:7} with Node $have"
npm --prefix "$work/src" ci
npm --prefix "$work/src" run build
dist="$work/src/dist"
[ -f "$dist/index.html" ] || die "the build produced no dist/index.html"

# 4. Serve files as-is.
: > "$dist/.nojekyll"

# 5. Commit on top of gh-pages. The parent is the remote branch when it exists, so a publish
#    from another clone is built upon rather than overwritten.
remote_tip="$(git -C "$REPO" ls-remote --heads "$REMOTE" "$BRANCH" | cut -f1)"
local_tip="$(git -C "$REPO" rev-parse --verify --quiet "refs/heads/$BRANCH" || true)"
if [ -n "$remote_tip" ]; then
  git -C "$REPO" fetch --quiet "$REMOTE" "+refs/heads/$BRANCH:refs/remotes/$REMOTE/$BRANCH"
  if [ -n "$local_tip" ] && ! git -C "$REPO" merge-base --is-ancestor "$local_tip" "$remote_tip"; then
    die "local $BRANCH has commits that are not on $REMOTE/$BRANCH; reconcile them before publishing"
  fi
  parent="$remote_tip"
else
  parent="$local_tip"
fi

export GIT_INDEX_FILE="$work/index"
# --force: the build output is authoritative, so no global or repo ignore rule may drop a file.
git --git-dir="$GIT_DIR_ABS" --work-tree="$dist" -C "$dist" add --all --force -- .
tree="$(git --git-dir="$GIT_DIR_ABS" write-tree)"
unset GIT_INDEX_FILE

if [ -n "$parent" ] && [ "$(git -C "$REPO" rev-parse "$parent^{tree}")" = "$tree" ]; then
  echo "publish: $BRANCH already holds this exact build; nothing to publish"
  echo "publish: live commit $parent"
  exit 0
fi

msg="publish: build of $src_ref@$src_sha"
if [ -n "$parent" ]; then
  commit="$(git -C "$REPO" commit-tree "$tree" -p "$parent" -m "$msg")"
else
  commit="$(git -C "$REPO" commit-tree "$tree" -m "$msg")"
fi
git -C "$REPO" update-ref "refs/heads/$BRANCH" "$commit"

# 6. Push, then verify from the remote rather than trusting the push's exit banner.
git -C "$REPO" push "$REMOTE" "refs/heads/$BRANCH:refs/heads/$BRANCH"
pushed="$(git -C "$REPO" ls-remote --heads "$REMOTE" "$BRANCH" | cut -f1)"
[ "$pushed" = "$commit" ] || die "$REMOTE/$BRANCH is at ${pushed:-nothing}, expected $commit"

echo "publish: published $commit to $REMOTE/$BRANCH (source $src_ref@$src_sha)"
