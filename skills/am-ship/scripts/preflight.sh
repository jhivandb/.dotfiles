#!/usr/bin/env bash
set -euo pipefail

# Preflight safety check for the agent-manager repo.
#
# Identifies the repo by its remotes (NOT by filesystem path, machine, or
# remote name) so it works in any clone or linked worktree, anywhere.
# The one invariant it enforces: a bare `git push` must reach YOUR fork
# (origin) and nowhere else — never the canonical upstream (wso2/agent-manager)
# and never a collaborator's fork.

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

# True if the URL points at the canonical upstream wso2/agent-manager.
is_wso2_url() {
  case "$1" in
    *[:/]wso2/agent-manager | *[:/]wso2/agent-manager.git) return 0 ;;
    *) return 1 ;;
  esac
}

# True if the URL points at any fork named agent-manager.
is_am_url() {
  case "$1" in
    *[:/]*/agent-manager | *[:/]*/agent-manager.git) return 0 ;;
    *) return 1 ;;
  esac
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
cd "$repo_root"

# --- Identify the repo by remote URL, not by path or remote name ---
is_am=0
wso2_remotes=()   # remotes pointing at the canonical upstream (never push here)
origin_url=""
while IFS= read -r remote; do
  [[ -n "$remote" ]] || continue
  url="$(git remote get-url "$remote" 2>/dev/null || true)"
  [[ -n "$url" ]] || continue
  if is_am_url "$url"; then
    is_am=1
  fi
  if is_wso2_url "$url"; then
    wso2_remotes+=("$remote")
  fi
  if [[ "$remote" == "origin" ]]; then
    origin_url="$url"
  fi
done < <(git remote)

[[ "$is_am" -eq 1 ]] || die "this does not look like the agent-manager repo (no remote points at */agent-manager)"

branch="$(git branch --show-current)"
[[ -n "$branch" ]] || die "detached HEAD; create or switch to a feature branch before pushing"

tracking="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
branch_remote="$(git config "branch.${branch}.remote" 2>/dev/null || true)"
push_remote="$(git config "branch.${branch}.pushRemote" 2>/dev/null || true)"
default_push_remote="$(git config remote.pushDefault 2>/dev/null || true)"

# Where would a bare `git push` actually go? (git's resolution order)
effective_push="${push_remote:-${default_push_remote:-${branch_remote:-origin}}}"
effective_url="$(git remote get-url "$effective_push" 2>/dev/null || true)"
if [[ -z "$effective_url" ]]; then
  # Not a known remote name — branch.<b>.remote may be a raw URL.
  case "$effective_push" in
    *://* | *@*:*) effective_url="$effective_push" ;;
  esac
fi

printf 'Repository:  %s\n' "$repo_root"
printf 'Branch:      %s\n' "$branch"
printf 'Tracking:    %s\n' "${tracking:-none}"
printf 'Bare push -> %s\n' "${effective_url:-$effective_push}"
printf 'Your fork:   %s\n' "${origin_url:-origin (not configured)}"
if [[ ${#wso2_remotes[@]} -gt 0 ]]; then
  printf 'Upstream:    %s (NEVER push)\n' "${wso2_remotes[*]}"
else
  printf 'Upstream:    none configured\n'
fi
printf '\nRemotes:\n'
git remote -v

failed=0

# 1) main is a shared branch — branch off before the normal workflow.
if [[ "$branch" == "main" ]]; then
  warn "current branch is 'main'; create a feature branch before the push/PR workflow"
  failed=1
fi

# 2) origin itself must be your fork, not the canonical upstream.
if [[ -n "$origin_url" ]] && is_wso2_url "$origin_url"; then
  warn "'origin' points at the canonical upstream (wso2/agent-manager); add your own fork and push there explicitly — do not push to origin"
  failed=1
fi

# 3) A bare `git push` must reach your fork (origin) and nowhere else.
bare_push_ok=0
if [[ "$effective_push" == "origin" ]] && ! { [[ -n "$origin_url" ]] && is_wso2_url "$origin_url"; }; then
  bare_push_ok=1
elif [[ -n "$origin_url" && -n "$effective_url" && "$effective_url" == "$origin_url" ]] && ! is_wso2_url "$origin_url"; then
  bare_push_ok=1
fi

if [[ "$bare_push_ok" -ne 1 ]]; then
  if [[ -n "$effective_url" ]] && is_wso2_url "$effective_url"; then
    warn "a bare 'git push' on '$branch' would reach the canonical upstream (wso2/agent-manager) — NEVER push there. Push explicitly: git push -u origin HEAD"
  else
    warn "a bare 'git push' on '$branch' would reach '${effective_url:-$effective_push}', not your fork (origin). Push explicitly: git push -u origin HEAD"
  fi
  failed=1
fi

printf '\nRecent commit subjects:\n'
git log --oneline -12

cat <<'EOF'

Run only the generators that match your diff (see SKILL.md "Run the relevant generators" table).
Common ones:
  make am-gen-client                            # if agent-manager-service/docs/api_v1_openapi.yaml changed
  cd agent-manager-service && make codegen     # handler/model changes in agent-manager-service
  cd agent-manager-service && make wire        # wire-binding changes
  make gen-eval-artifacts                       # evaluator code or libs/amp-evaluation/

Use explicit push target:
  git push -u origin HEAD
EOF

if [[ "$failed" -ne 0 ]]; then
  exit 2
fi
