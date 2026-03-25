# 此脚本为新项目设置了基本的 GitHub 仓库设置，包括分支保护规则和环境配置。
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

# 1) Branch protection on main
curl -sS -X PUT \
  -H "$auth_header" \
  -H "$accept_header" \
  "$api/repos/$owner/$repo/branches/main/protection" \
  -d @- >/dev/null <<JSON
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context": "pipeline / validate-build-scan"},
      {"context": "security / semgrep"},
      {"context": "security / codeql (actions, none)"},
      {"context": "security / codeql (go, autobuild)"}
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
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

# 2) Create environments
for env in dev staging prod; do
  curl -sS -X PUT \
    -H "$auth_header" \
    -H "$accept_header" \
    "$api/repos/$owner/$repo/environments/$env" \
    -d '{"wait_timer":0,"reviewers":[],"deployment_branch_policy":null}' >/dev/null
done

echo "GitHub baseline configured: main protection + environments(dev/staging/prod)."
echo "Next: set required reviewers for staging/prod in GitHub UI."
