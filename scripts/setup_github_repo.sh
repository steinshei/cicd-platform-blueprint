#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   GITHUB_TOKEN=xxx ./scripts/setup_github_repo.sh steinshei cicd-platform-blueprint

if [ "$#" -ne 2 ]; then
  echo "usage: GITHUB_TOKEN=<token> $0 <owner> <repo>"
  exit 1
fi

owner="$1"
repo="$2"

auth_header="Authorization: Bearer ${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
accept_header="Accept: application/vnd.github+json"
api="https://api.github.com"

ensure_branch() {
  local branch="$1"
  if curl -sS -o /dev/null -w "%{http_code}" \
      -H "$auth_header" -H "$accept_header" \
      "$api/repos/$owner/$repo/branches/$branch" | grep -q "^200$"; then
    return 0
  fi

  main_sha="$(curl -sS -H "$auth_header" -H "$accept_header" \
    "$api/repos/$owner/$repo/git/ref/heads/main" | jq -r '.object.sha')"
  if [ -z "$main_sha" ] || [ "$main_sha" = "null" ]; then
    echo "failed to read main SHA, cannot create branch: $branch"
    exit 1
  fi

  curl -sS -X POST \
    -H "$auth_header" \
    -H "$accept_header" \
    "$api/repos/$owner/$repo/git/refs" \
    -d "{\"ref\":\"refs/heads/$branch\",\"sha\":\"$main_sha\"}" >/dev/null
  echo "created branch: $branch from main"
}

protect_branch() {
  local branch="$1"
  local checks_json="$2"
  local approving_review_count="$3"

  curl -sS -X PUT \
    -H "$auth_header" \
    -H "$accept_header" \
    "$api/repos/$owner/$repo/branches/$branch/protection" \
    -d @- >/dev/null <<JSON
{
  "required_status_checks": {
    "strict": true,
    "checks": ${checks_json}
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": ${approving_review_count},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON
}

main_checks='[
  {"context":"pipeline / validate-build-scan"},
  {"context":"security / semgrep"},
  {"context":"security / codeql (actions, none)"},
  {"context":"security / codeql (go, autobuild)"},
  {"context":"pr-guard / main-source-guard (pull_request)"}
]'

develop_checks='[
  {"context":"pipeline / validate-build-scan"},
  {"context":"security / semgrep"},
  {"context":"security / codeql (actions, none)"},
  {"context":"security / codeql (go, autobuild)"}
]'

ensure_branch "develop"
protect_branch "main" "$main_checks" 1
protect_branch "develop" "$develop_checks" 0

for env in dev staging prod; do
  curl -sS -X PUT \
    -H "$auth_header" \
    -H "$accept_header" \
    "$api/repos/$owner/$repo/environments/$env" \
    -d '{"wait_timer":0,"reviewers":[],"deployment_branch_policy":null}' >/dev/null
done

echo "GitHub baseline configured: branch protection(main/develop) + environments(dev/staging/prod)."
echo "Next in GitHub UI:"
echo "  1) set required reviewers for staging/prod environments"
echo "  2) enable repository setting: Allow auto-merge"
echo "  3) set repo variable AUTO_PR_REVIEWERS=alice,bob (comma-separated GitHub usernames)"
echo "  4) run: ./scripts/verify_required_checks.sh ${owner} ${repo}"
echo "Default branch review policy applied: main=1 approval, develop=0 approval."
