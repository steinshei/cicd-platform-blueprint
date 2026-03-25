# 此脚本会使用 Argo Rollouts 对给定环境中的指定服务进行回滚操作。
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <service> <environment>"
  echo "example: $0 sample-service prod"
  exit 1
fi

service="$1"
environment="$2"

if [[ "$environment" != "dev" && "$environment" != "staging" && "$environment" != "prod" ]]; then
  echo "invalid environment: $environment"
  exit 1
fi

echo "Rolling back ${service} in ${environment} via Argo Rollouts"
kubectl argo rollouts undo "rollout/${service}" -n "${service}"

echo "Rollback command submitted. Verify with:"
echo "kubectl argo rollouts get rollout ${service} -n ${service}"
