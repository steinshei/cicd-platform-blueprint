# 中小企业 CI/CD 平台蓝图（单业务仓接入企业多仓架构）

本仓库是业务仓样板，CI/CD 核心能力由平台仓提供并版本化复用：`steinshei/platform-cicd@v1.1`。

## 当前落地策略

- `dev`：自动推进（自动创建并自动合并 `deploy(dev)` PR）
- `staging/prod`：必须审批，生产由人工合并
- 业务仓仅保留轻量入口 workflow，重逻辑统一放平台仓

## 当前包含能力

- 基于 GitHub Actions + 平台仓复用 workflow 的 CI/CD
- GitOps 部署（Argo CD）与晋级策略（staging -> prod）
- 渐进发布模板（Argo Rollouts 5% -> 20% -> 50% -> 100%）
- Kyverno 基线策略（禁用 latest、资源约束、签名校验）
- DORA 事件采集、Artifact 汇总、每周报表工作流
- OpenTofu 基础骨架与运维 Runbook

## 业务仓必备设置

1. 创建 Environments：`dev`、`staging`、`prod`
2. `staging` 和 `prod` 配置必需审批人
3. 配置可选 secrets：`COSIGN_PRIVATE_KEY`、`COSIGN_PASSWORD`（未配置走 keyless）
4. 配置 `CI_BOT_TOKEN`（用于 `deploy(dev)` PR 自动合并）
5. 执行仓库基线脚本：

```bash
export GITHUB_TOKEN='<repo-admin-token>'
./scripts/setup_github_repo.sh <owner> <repo>
```

## 必需检查名（分支保护）

- `pipeline / validate-build-scan`
- `security / semgrep`
- `security / codeql (actions, none)`
- `security / codeql (go, autobuild)`

## 标准发布链路

1. 开发提交到功能分支并发起到 `main` 的 PR
2. PR 通过后合并到 `main`，触发平台 CI（构建/测试/扫描/SBOM/签名）
3. 自动创建 `deploy(dev)` PR 并自动合并
4. Argo CD 同步 `dev`
5. 手动触发 `promote` workflow 晋级到 `staging`，再创建 `prod` PR（人工合并）

## DORA 周报

- 工作流：`.github/workflows/dora-weekly-report.yaml`
- 频率：每周一 UTC 02:00（可手动触发）
- 输出：`weekly-report.json` + `weekly-report.md`（Artifact）
- 指标：Lead Time、Deployment Frequency、MTTR、Change Failure Rate

## 新服务接入（MVP）

```bash
./scripts/onboard_service.sh <service-name> [owner-email] [tier] [runbook-path]
```

脚本会生成：

- `apps/<service>/` 最小服务骨架
- `.github/workflows/<service>-ci.yaml` 轻量入口 workflow（引用 `platform-cicd@v1.1`）
- `gitops/environments/{dev,staging,prod}/<service>-values.yaml`
- `service-catalog/<service>.yaml`

## 集群侧引导（Argo + Kyverno）

```bash
kubectl create namespace argocd
kubectl apply -f gitops/bootstrap/argocd-project.yaml
kubectl apply -f gitops/bootstrap/sample-service-dev-app.yaml
kubectl apply -f gitops/bootstrap/sample-service-staging-app.yaml
kubectl apply -f gitops/bootstrap/sample-service-prod-app.yaml

kubectl apply -f security/kyverno/disallow-latest-tag.yaml
kubectl apply -f security/kyverno/require-resources.yaml
kubectl apply -f security/kyverno/verify-image-signature.yaml
kubectl apply -f security/kyverno/platform-namespace-exception.yaml
```

更多操作见：

- `runbooks/operations.md`
- `runbooks/incidents.md`
- `docs/BUSINESS_REPO_STANDARD_CHECKLIST.md`
