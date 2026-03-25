# 此脚本会收集 DORA 事件，并将其保存为 JSON 文件至“dora/events”目录中。
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

mkdir -p dora/events
outfile="dora/events/${timestamp//:/-}-${event_type}-${environment}-${service}.json"

cat > "$outfile" <<JSON
{
  "event_type": "${event_type}",
  "timestamp": "${timestamp}",
  "environment": "${environment}",
  "service": "${service}",
  "version": "${version}",
  "status": "${status}",
  "actor": "${actor}",
  "run_id": "${run_id}"
}
JSON

echo "DORA event written to ${outfile}"
