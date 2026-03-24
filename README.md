# 中小企业 CI/CD 平台蓝图（GitHub + Kubernetes + GitOps）

这个仓库用于快速搭建一套适合约 100 人规模公司的生产级 CI/CD 平台基础设施。

## 包含内容

- 基于 GitHub Actions 的 CI：测试 / 构建 / 扫描 / SBOM / 签名 / 产物证明（attestation）
- 基于 Argo CD 的 GitOps 部署模型
- 基于 Argo Rollouts 的渐进发布（5% -> 20% -> 50% -> 100%）
- 环境晋级策略（仅允许 `staging` -> `prod`）
- 基于 Kyverno 的策略治理基线
- DORA 指标事件采集脚本与事件结构定义
- OpenTofu 基础骨架（基础设施与 CI 身份）
- 服务接入模板与运维 Runbook

## 仓库结构

- `.github/workflows`：CI/CD 工作流
- `ci/`：可复用 CI 流水线模板
- `deploy/helm/sample-service`：示例 Helm 部署模板
- `gitops/`：按环境划分的期望状态
- `security/kyverno`：准入策略基线
- `dora/`：事件结构与采集脚本
- `runbooks/`：运维与故障处理手册
- `iac/opentofu`：基础设施骨架
- `apps/sample-service`：用于打通链路的最小示例服务

## 分支模型

- `main`
- `release/*`
- `hotfix/*`

## 仓库必备设置

1. 在 GitHub 中创建 Environments：`dev`、`staging`、`prod`
2. 为 `staging` 和 `prod` 环境配置必需审批人
3. 配置环境密钥：
   - `REGISTRY_USERNAME`、`REGISTRY_PASSWORD`
   - `COSIGN_PRIVATE_KEY`、`COSIGN_PASSWORD`（或使用基于 OIDC 的无密钥签名）
4. 开启 OIDC，并确保 Actions 具备读写权限

## 标准发布链路

1. 向 `main` 提交 PR，触发 CI（测试、构建、扫描）
2. 合并到 `main` 后，构建并推送镜像，同时生成签名和 SBOM
3. 工作流自动更新 `gitops/environments/dev` 中的镜像 tag
4. Argo CD 自动同步并部署到 `dev`
5. 通过 promotion 工作流晋级到 `staging`，再晋级到 `prod`（带人工审批）

## 快速开始

```bash
git init
# 提交本仓库并推送到 GitHub
# 配置 GitHub Environments 和 secrets
```

之后你可以在 `apps/sample-service` 做一次改动，合并到 `main`，再按流程晋级各环境。

## 集群侧引导命令（Bootstrap）

```bash
# 1）安装 Argo CD 和 Argo Rollouts（按你的集群工具链调整）
kubectl create namespace argocd

# 2）应用 Project 和 Application
kubectl apply -f gitops/bootstrap/argocd-project.yaml
kubectl apply -f gitops/bootstrap/sample-service-dev-app.yaml
kubectl apply -f gitops/bootstrap/sample-service-staging-app.yaml
kubectl apply -f gitops/bootstrap/sample-service-prod-app.yaml

# 3）安装 Kyverno 后，应用策略基线
kubectl apply -f security/kyverno/disallow-latest-tag.yaml
kubectl apply -f security/kyverno/require-resources.yaml
kubectl apply -f security/kyverno/verify-image-signature.yaml
```
