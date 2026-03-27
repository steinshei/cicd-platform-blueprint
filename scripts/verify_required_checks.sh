#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: GITHUB_TOKEN=<token> $0 <owner> <repo>"
  exit 1
fi

owner="$1"
repo="$2"
token="${GITHUB_TOKEN:-}"
if [ -z "${token}" ]; then
  echo "GITHUB_TOKEN is required"
  exit 1
fi

api="https://api.github.com/repos/${owner}/${repo}/branches"
accept="Accept: application/vnd.github+json"
auth="Authorization: Bearer ${token}"

expected_main='[
  "pipeline / validate-build-scan",
  "security / semgrep",
  "security / codeql (actions, none)",
  "security / codeql (go, autobuild)",
  "pr-guard / main-source-guard"
]'

expected_develop='[
  "pipeline / validate-build-scan",
  "security / semgrep",
  "security / codeql (actions, none)",
  "security / codeql (go, autobuild)"
]'

check_branch() {
  local branch="$1"
  local expected="$2"

  local raw
  raw="$(curl -sS -H "${auth}" -H "${accept}" "${api}/${branch}/protection")"
  if jq -e '.message? != null' >/dev/null <<<"${raw}"; then
    echo "branch=${branch}"
    echo "  result  : ERROR ($(jq -r '.message' <<<"${raw}"))"
    return 1
  fi

  local current
  current="$(jq -c '(.required_status_checks.checks // [] | map(.context) | sort)' <<<"${raw}")"

  local want
  want="$(jq -c 'sort' <<<"${expected}")"

  echo "branch=${branch}"
  echo "  expected: ${want}"
  echo "  current : ${current}"

  if [ "${current}" = "${want}" ]; then
    echo "  result  : OK"
    return 0
  fi

  echo "  result  : MISMATCH"
  return 1
}

ok=0
check_branch "main" "${expected_main}" || ok=1
check_branch "develop" "${expected_develop}" || ok=1

if [ "${ok}" -ne 0 ]; then
  echo "required checks verification failed"
  exit 1
fi

echo "required checks verification passed"
