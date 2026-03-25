#!/usr/bin/env bash
set -euo pipefail

repo="${GITHUB_REPOSITORY:-}"
token="${GITHUB_TOKEN:-}"
days="${1:-7}"
output_dir="${2:-dora/weekly-input}"

if [ -z "${repo}" ]; then
  echo "GITHUB_REPOSITORY is required (example: owner/repo)"
  exit 1
fi

if [ -z "${token}" ]; then
  echo "GITHUB_TOKEN is required"
  exit 1
fi

mkdir -p "${output_dir}"
tmp_json="$(mktemp)"
tmp_zip="$(mktemp).zip"

cutoff_epoch="$(date -u -v-"${days}"d +%s 2>/dev/null || true)"
if [ -z "${cutoff_epoch}" ]; then
  export DORA_DAYS="${days}"
  cutoff_epoch="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
import os
days = int(os.environ.get("DORA_DAYS", "7"))
print(int((datetime.now(timezone.utc)-timedelta(days=days)).timestamp()))
PY
)"
fi

api="https://api.github.com/repos/${repo}/actions/artifacts?per_page=100"
curl -sS -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.github+json" "${api}" > "${tmp_json}"

jq -r '.artifacts[] | select((.name|startswith("dora-event-")) and (.expired==false)) | [.archive_download_url,.created_at,.name] | @tsv' "${tmp_json}" |
while IFS=$'\t' read -r url created_at name; do
  created_epoch="$(python3 - <<PY
from datetime import datetime, timezone
print(int(datetime.fromisoformat("${created_at}".replace("Z","+00:00")).timestamp()))
PY
)"
  if [ "${created_epoch}" -lt "${cutoff_epoch}" ]; then
    continue
  fi
  curl -sS -L -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.github+json" "${url}" -o "${tmp_zip}"
  unzip -o -q "${tmp_zip}" -d "${output_dir}/"
  echo "Downloaded: ${name}"
done

rm -f "${tmp_json}" "${tmp_zip}"
echo "DORA artifacts collected under ${output_dir}"
