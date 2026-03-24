#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <service-name>"
  exit 1
fi

service="$1"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "${repo_root}/deploy/helm/${service}/templates"
mkdir -p "${repo_root}/gitops/environments/dev"
mkdir -p "${repo_root}/gitops/environments/staging"
mkdir -p "${repo_root}/gitops/environments/prod"

cat > "${repo_root}/gitops/environments/dev/${service}-values.yaml" <<YAML
image:
  repository: ghcr.io/your-org/${service}
  tag: bootstrap-dev
YAML

cat > "${repo_root}/gitops/environments/staging/${service}-values.yaml" <<YAML
image:
  repository: ghcr.io/your-org/${service}
  tag: bootstrap-staging
YAML

cat > "${repo_root}/gitops/environments/prod/${service}-values.yaml" <<YAML
image:
  repository: ghcr.io/your-org/${service}
  tag: bootstrap-prod
YAML

cat > "${repo_root}/gitops/bootstrap/${service}-dev-app.yaml" <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${service}-dev
  namespace: argocd
spec:
  project: platform-apps
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: deploy/helm/${service}
    helm:
      valueFiles:
        - ../../../gitops/environments/dev/${service}-values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: ${service}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML

echo "Scaffolded GitOps values and Argo app for ${service}."
