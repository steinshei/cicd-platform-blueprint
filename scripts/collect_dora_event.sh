#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
  echo "usage: $0 <event_type> <environment> <service> <version> <status>"
  exit 1
fi

event_type="$1"
environment="$2"
service="$3"
version="$4"
status="$5"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
actor="${GITHUB_ACTOR:-local-user}"
run_id="${GITHUB_RUN_ID:-local-run}"
repo="${GITHUB_REPOSITORY:-local/local}"
run_url="${GITHUB_SERVER_URL:-https://github.com}/${repo}/actions/runs/${run_id}"
output_dir="${DORA_OUTPUT_DIR:-dora/events}"

mkdir -p "${output_dir}"
outfile="${output_dir}/${timestamp//:/-}-${event_type}-${environment}-${service}.json"

cat > "$outfile" <<JSON
{
  "event_type": "${event_type}",
  "timestamp": "${timestamp}",
  "environment": "${environment}",
  "service": "${service}",
  "version": "${version}",
  "status": "${status}",
  "actor": "${actor}",
  "run_id": "${run_id}",
  "repository": "${repo}",
  "run_url": "${run_url}"
}
JSON

echo "DORA event written to ${outfile}"
