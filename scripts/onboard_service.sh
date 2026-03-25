# 此脚本会为新服务生成必要的 GitOps 文件，包括 Helm 清单模板和 Argo CD 应用程序配置文件。
# 它为在不同环境（开发、测试、生产）中部署该服务创建了统一的结构，并为每个环境设置了初始的镜像存储库和标签值。
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
