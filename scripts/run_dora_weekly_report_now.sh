#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
  echo "usage: GITHUB_TOKEN=<token> $0 <owner> <repo> [ref] [days]"
  echo "example: $0 steinshei cicd-platform-blueprint develop 7"
  exit 1
fi

owner="$1"
repo="$2"
ref="${3:-develop}"
days="${4:-7}"

token="${GITHUB_TOKEN:-}"
if [ -z "${token}" ]; then
  echo "GITHUB_TOKEN is required"
  exit 1
fi

api="https://api.github.com/repos/${owner}/${repo}"
accept="Accept: application/vnd.github+json"
auth="Authorization: Bearer ${token}"

echo "Dispatching dora-weekly-report on ref=${ref}, days=${days} ..."
resp="$(curl -sS -X POST \
  -H "${auth}" \
  -H "${accept}" \
  "${api}/actions/workflows/dora-weekly-report.yaml/dispatches?return_run_details=true" \
  -d "{\"ref\":\"${ref}\",\"inputs\":{\"days\":\"${days}\"}}")"

run_url="$(jq -r '.html_url // empty' <<<"${resp}")"
run_id="$(jq -r '.workflow_run_id // empty' <<<"${resp}")"

if [ -n "${run_url}" ] && [ -n "${run_id}" ]; then
  echo "Triggered run: ${run_id}"
  echo "Open: ${run_url}"
  exit 0
fi

echo "Dispatch accepted. Querying latest workflow_dispatch run ..."
sleep 2
latest="$(curl -sS -H "${auth}" -H "${accept}" \
  "${api}/actions/workflows/dora-weekly-report.yaml/runs?event=workflow_dispatch&branch=${ref}&per_page=1")"
latest_id="$(jq -r '.workflow_runs[0].id // empty' <<<"${latest}")"
latest_html="$(jq -r '.workflow_runs[0].html_url // empty' <<<"${latest}")"
latest_status="$(jq -r '.workflow_runs[0].status // empty' <<<"${latest}")"

if [ -n "${latest_id}" ]; then
  echo "Latest run: ${latest_id} (status=${latest_status})"
  echo "Open: ${latest_html}"
  exit 0
fi

echo "Triggered, but no run discovered yet. Check Actions tab manually."
