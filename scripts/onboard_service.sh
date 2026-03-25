#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
  echo "usage: $0 <service-name> [owner-email] [tier] [runbook-path]"
  exit 1
fi

service="$1"
owner="${2:-platform@example.com}"
tier="${3:-tier-2}"
runbook="${4:-runbooks/operations.md}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
repo_slug="$(git -C "${repo_root}" config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##' || true)"
if [ -z "${repo_slug}" ]; then
  repo_slug="your-org/your-repo"
fi

service_dir="${repo_root}/apps/${service}"
workflow_file="${repo_root}/.github/workflows/${service}-ci.yaml"
catalog_dir="${repo_root}/service-catalog"
catalog_file="${catalog_dir}/${service}.yaml"

mkdir -p "${service_dir}" "${catalog_dir}"
mkdir -p "${repo_root}/gitops/environments/dev" "${repo_root}/gitops/environments/staging" "${repo_root}/gitops/environments/prod"

if [ ! -f "${service_dir}/go.mod" ]; then
  cat > "${service_dir}/go.mod" <<EOF
module github.com/${repo_slug}/apps/${service}

go 1.22
EOF
fi

if [ ! -f "${service_dir}/main.go" ]; then
  cat > "${service_dir}/main.go" <<'EOF'
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprint(w, "ok")
	})
	log.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
EOF
fi

if [ ! -f "${service_dir}/main_test.go" ]; then
  cat > "${service_dir}/main_test.go" <<'EOF'
package main

import "testing"

func TestSmoke(t *testing.T) {
	if 1+1 != 2 {
		t.Fatal("unexpected math failure")
	}
}
EOF
fi

if [ ! -f "${service_dir}/Dockerfile" ]; then
  cat > "${service_dir}/Dockerfile" <<'EOF'
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY . .
RUN go build -o /out/app .

FROM alpine:3.20
RUN adduser -D -u 10001 appuser
USER 10001
COPY --from=build /out/app /app
EXPOSE 8080
ENTRYPOINT ["/app"]
EOF
fi

for env in dev staging prod; do
  values_file="${repo_root}/gitops/environments/${env}/${service}-values.yaml"
  if [ ! -f "${values_file}" ]; then
    cat > "${values_file}" <<EOF
image:
  repository: ghcr.io/${repo_slug}/${service}
  tag: bootstrap-${env}
EOF
  fi
done

if [ ! -f "${catalog_file}" ]; then
  cat > "${catalog_file}" <<EOF
apiVersion: platform.internal/v1
kind: ServiceCatalog
metadata:
  name: ${service}
spec:
  owner: ${owner}
  tier: ${tier}
  language: go
  repository: github.com/${repo_slug}
  runtime:
    type: kubernetes
    namespace: ${service}
  slo:
    availability: 99.9
    latency_p95_ms: 250
  runbook: ${runbook}
EOF
fi

if [ ! -f "${workflow_file}" ]; then
  cat > "${workflow_file}" <<EOF
name: ${service}-ci

on:
  pull_request:
    branches: [develop]
    paths:
      - apps/${service}/**
      - gitops/environments/dev/${service}-values.yaml
  push:
    branches: [develop]
    paths:
      - apps/${service}/**
      - gitops/environments/dev/${service}-values.yaml

permissions:
  contents: write
  pull-requests: write
  id-token: write
  security-events: write
  attestations: write
  packages: write

jobs:
  pipeline:
    uses: steinshei/platform-cicd/.github/workflows/reusable-ci.yml@v1.1
    with:
      service_name: ${service}
      context_dir: apps/${service}
      dockerfile: apps/${service}/Dockerfile
      run_tests: true
    secrets: inherit

  update-dev-gitops:
    needs: [pipeline]
    if: github.event_name == 'push'
    uses: steinshei/platform-cicd/.github/workflows/reusable-deploy-dev.yml@v1.1
    with:
      service_name: ${service}
      values_file: gitops/environments/dev/${service}-values.yaml
      image_tag: \${{ github.sha }}
      skip_if_deploy_commit: true
    secrets:
      ci_bot_token: \${{ secrets.CI_BOT_TOKEN }}
EOF
fi

echo "Onboarding completed for ${service}"
echo "- app scaffold: apps/${service}"
echo "- workflow: .github/workflows/${service}-ci.yaml"
echo "- gitops values: gitops/environments/{dev,staging,prod}/${service}-values.yaml"
echo "- service catalog: service-catalog/${service}.yaml"
