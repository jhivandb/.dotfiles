#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
cd "$repo_root"

upstream_url="$(git remote get-url upstream 2>/dev/null || true)"
case "$upstream_url" in
  *github.com[:/]wso2/agent-manager* ) ;;
  * ) die "this does not look like wso2/agent-manager; upstream is '${upstream_url:-missing}'" ;;
esac

branch="$(git branch --show-current)"
[[ -n "$branch" ]] || die "detached HEAD; create or switch to a feature branch before pushing"

tracking="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
branch_remote="$(git config "branch.${branch}.remote" 2>/dev/null || true)"
push_remote="$(git config "branch.${branch}.pushRemote" 2>/dev/null || true)"
default_push_remote="$(git config remote.pushDefault 2>/dev/null || true)"

printf 'Repository: %s\n' "$repo_root"
printf 'Branch:     %s\n' "$branch"
printf 'Tracking:   %s\n' "${tracking:-none}"
printf 'Remote:     %s\n' "${branch_remote:-none}"
printf 'PushRemote: %s\n' "${push_remote:-${default_push_remote:-none}}"
printf '\nRemotes:\n'
git remote -v

failed=0
if [[ "$branch" == "main" ]]; then
  warn "current branch is main; create a feature branch before the normal push/PR workflow"
  failed=1
fi

if [[ "$tracking" == upstream/* || "$branch_remote" == "upstream" ]]; then
  warn "current branch is configured against ${tracking:-upstream}; do not use plain git push"
  failed=1
fi

if [[ "$push_remote" == "upstream" || "$default_push_remote" == "upstream" ]]; then
  warn "push remote is configured as upstream; change it or push explicitly to origin"
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
