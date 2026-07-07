#!/bin/bash
set -euo pipefail

WORKSPACE="/workspace"

# ---- git identity (used for commits made inside OpenCode) ----
git config --global user.name  "${GIT_USER_NAME:-OpenCode}"
git config --global user.email "${GIT_USER_EMAIL:-opencode@localhost}"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global push.autoSetupRemote true
# Bind/volume-mounted repos may be owned by a different uid; don't let git refuse to run.
git config --global --add safe.directory '*'

# ---- authenticate to GitHub via PAT (HTTPS URL rewrite) ----
if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global \
    url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf \
    "https://github.com/"
fi

# ---- clone / update requested repos into /workspace (in the background) ----
# GITHUB_REPOS is a space/newline-separated list of specs:
#   owner/repo          -> default branch
#   owner/repo@branch   -> specific branch
# Runs in a subshell so opencode web starts immediately; repos populate
# asynchronously and a single failed clone never aborts the loop.
if [ -n "${GITHUB_REPOS:-}" ]; then
  (
    set +e
    for spec in $GITHUB_REPOS; do
      [ -z "$spec" ] && continue
      repo="${spec%%@*}"
      branch=""
      case "$spec" in
        *@*) branch="${spec##*@}" ;;
      esac
      name="${repo##*/}"; name="${name%.git}"
      dest="${WORKSPACE}/${name}"
      if [ -d "${dest}/.git" ]; then
        echo "[opencode] updating ${name}…"
        git -C "$dest" fetch --all --prune >/dev/null 2>&1 || true
        if [ -n "$branch" ]; then
          git -C "$dest" checkout "$branch" >/dev/null 2>&1 || true
        fi
        git -C "$dest" pull --ff-only >/dev/null 2>&1 || true
      else
        echo "[opencode] cloning ${repo}${branch:+ @ ${branch}}…"
        if git clone --recurse-submodules "https://github.com/${repo}" "$dest" 2>/dev/null; then
          if [ -n "$branch" ]; then
            git -C "$dest" checkout "$branch" >/dev/null 2>&1 || true
          fi
        else
          echo "[opencode] WARNING: could not clone ${repo}"
        fi
      fi
    done
    echo "[opencode] repo sync complete"
  ) >> /tmp/repo-sync.log 2>&1 &
fi

cd "$WORKSPACE"
exec opencode web --hostname 0.0.0.0 --port 4096
