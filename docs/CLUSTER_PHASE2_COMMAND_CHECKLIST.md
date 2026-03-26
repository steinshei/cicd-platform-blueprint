# 集群侧 Phase2 命令版清单

适用：已具备可用 Kubernetes 集群，仓库已完成业务仓 CI/CD 主链路验收。

## 0. 前置检查

```bash
kubectl version --short
kubectl config current-context
kubectl get ns
```

通过标准：
- `kubectl` 可用
- 当前 context 指向目标集群

## 1. 安装 Argo Rollouts（如未安装）

```bash
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=180s
kubectl argo rollouts version
```

通过标准：
- 控制器 `Available=True`
- `kubectl argo rollouts version` 可输出版本

## 2. 安装/检查 Kyverno（如未安装）

```bash
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm upgrade --install kyverno kyverno/kyverno -n kyverno
kubectl -n kyverno rollout status deploy/kyverno-admission-controller --timeout=180s
```

通过标准：
- `kyverno-admission-controller` Ready

## 3. 应用 GitOps bootstrap（Argo CD 项目与应用）

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f gitops/bootstrap/argocd-project.yaml
kubectl apply -f gitops/bootstrap/sample-service-dev-app.yaml
kubectl apply -f gitops/bootstrap/sample-service-staging-app.yaml
kubectl apply -f gitops/bootstrap/sample-service-prod-app.yaml
```

通过标准：
- `Application` 资源创建成功

## 4. 应用 Kyverno 策略（分层）

建议顺序：先观测，再强制。

```bash
kubectl apply -f security/kyverno/disallow-latest-tag.yaml
kubectl apply -f security/kyverno/require-resources.yaml
kubectl apply -f security/kyverno/verify-image-signature.yaml
kubectl apply -f security/kyverno/platform-namespace-exception.yaml
```

策略检查：

```bash
kubectl get cpol
kubectl get policyexception -A
```

## 5. 验证 Rollout 金丝雀策略

```bash
kubectl -n sample-service-dev get rollout
kubectl -n sample-service-dev get analysistemplate
kubectl argo rollouts get rollout sample-service -n sample-service-dev --watch
```

通过标准：
- 可看到 `setWeight` 5/20/50/100 阶段推进
- 当 `rollout.enableAnalysis=true` 时，Analysis step 可执行
- 当 `rollout.enableAnalysis=false` 时，流程不依赖 Prometheus 也可推进

## 6. 故障演练 A：镜像仓库不可用

```bash
kubectl -n sample-service-dev set image rollout/sample-service sample-service=invalid.registry.local/sample-service:broken
kubectl argo rollouts get rollout sample-service -n sample-service-dev --watch
```

恢复：

```bash
kubectl argo rollouts undo rollout/sample-service -n sample-service-dev
kubectl argo rollouts get rollout sample-service -n sample-service-dev --watch
```

## 7. 故障演练 B：配置错误

```bash
kubectl -n sample-service-dev set env rollout/sample-service BROKEN_CONFIG=true
kubectl argo rollouts get rollout sample-service -n sample-service-dev --watch
```

恢复：

```bash
kubectl -n sample-service-dev set env rollout/sample-service BROKEN_CONFIG-
kubectl argo rollouts undo rollout/sample-service -n sample-service-dev
```

## 8. 故障演练 C：探针失败

```bash
kubectl -n sample-service-dev patch rollout sample-service --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/wrong-healthz"}]'
kubectl argo rollouts get rollout sample-service -n sample-service-dev --watch
```

恢复：

```bash
kubectl -n sample-service-dev patch rollout sample-service --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/healthz"}]'
kubectl argo rollouts undo rollout/sample-service -n sample-service-dev
```

## 9. 演练结果留档

每次演练完成后，复制模板并补齐：

```bash
cp runbooks/drill-record-template.md runbooks/drill-record-$(date +%Y%m%d)-<type>.md
```

目标：
- 每类演练都有记录
- MTTR 可计算并可复盘
