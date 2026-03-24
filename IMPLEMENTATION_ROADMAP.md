# CI/CD 实施路线图（12 周）

## 第 1 阶段（第 0-4 周）：打通基线交付链路

- 第 1 周：
  - 在 GitHub 中落实分支策略与环境保护规则。
  - 配置 self-hosted runners（推荐在 Kubernetes 上通过 ARC 管理）。
  - 配置镜像仓库与签名相关密钥。
- 第 2 周：
  - 启用可复用 CI 流水线与安全扫描工作流。
  - 验证镜像构建、Trivy 漏洞门禁、SBOM 上传、Cosign 签名。
- 第 3 周：
  - 部署 Argo CD 并应用 `gitops/bootstrap/*`。
  - 验证合并到 `main` 后自动部署到 `dev`。
- 第 4 周：
  - 为 `staging` 和 `prod` 启用人工审批。
  - 验证 promotion 流程与工作流审计记录。

## 第 2 阶段（第 5-12 周）：渐进发布 + 治理 + 指标

- 第 5-6 周：
  - 启用 Argo Rollouts 金丝雀发布策略。
  - 执行回滚演练（镜像仓库不可用、配置错误、探针失败）。
- 第 7-8 周：
  - 应用 Kyverno 策略：禁用 latest、强制 resources、签名校验。
  - 为平台命名空间调优策略例外。
- 第 9-10 周：
  - 将 DORA 事件对接到数据存储与可视化链路。
  - 建立 Lead Time、Deployment Frequency、MTTR、Change Failure Rate 看板。
- 第 11-12 周：
  - 将服务接入流程产品化（`scripts/onboard_service.sh`）。
  - 完成值班与故障 Runbook，执行一次演练（game-day）。

## 阶段验收标准

- 可从工作流与 GitOps 数据中稳定计算交付周期与部署频率。
- 生产晋级具备审批、可审计、可回滚能力。
- 高危/严重漏洞与未签名制品可被有效阻断。
