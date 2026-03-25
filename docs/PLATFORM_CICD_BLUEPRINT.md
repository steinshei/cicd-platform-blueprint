# Platform-CICD 仓库蓝图

## 目标
创建组织级 CI/CD 平台仓库（`steinshei/platform-cicd`），集中承载可复用工作流、共享策略与接入标准，服务多个业务仓库。

## 预期产出
- 所有业务仓库统一一套可复用 CI/CD 基线
- 各仓库安全门禁一致
- 新服务快速接入（目标：<= 1 天）
- 明确分层：
  - `dev`：允许自动推进 / 自动合并
  - `staging/prod`：审批后手动合并

## 推荐仓库结构
```text
platform-cicd/
  .github/
    workflows/
      reusable-ci.yml
      reusable-security-sast.yml
      reusable-deploy-dev.yml
      reusable-promote.yml
  policies/
    kyverno/
      disallow-latest-tag.yaml
      require-resources.yaml
  templates/
    workflow/
      ci-entry-template.yaml
      security-entry-template.yaml
    repo/
      service-catalog.yaml
      deploy-values-template.yaml
  scripts/
    onboarding/
      bootstrap_repo.sh
      verify_repo_contract.sh
  docs/
    integration-guide.md
    versioning-policy.md
    rollback-guide.md
```

## 版本策略（重要）
- 业务仓库禁止引用 `@main`
- 通过标签发布工作流版本：
  - `v1`（主版本通道）
  - `v1.0.0`（不可变发布）
- 业务仓库引用方式建议：
  - `uses: steinshei/platform-cicd/.github/workflows/reusable-ci.yml@v1.1`

## 业务仓库接入契约
每个业务仓库至少提供：
- `Dockerfile`
- `deploy/helm/*` 或 `kustomize/*`
- `service-catalog.yaml`
- 仅保留轻量入口 workflow（调用平台仓可复用 workflow）

## 治理基线
- 分支保护 / 规则集：
  - 必需状态检查
  - 限制直接推送到 `main`
- 环境审批：
  - `staging`：必需审批人
  - `prod`：必需审批人
- 安全基线：
  - CodeQL + Semgrep + Trivy
  - SBOM + Cosign 签名

## 推广策略
1. 先在 2-3 个仓库试点。
2. 验证 DORA 指标与交付效率变化。
3. 分批扩展到全部业务仓库。
4. 业务仓库冻结本地复杂 workflow 逻辑，仅保留入口 workflow。

## 与当前蓝图仓库的兼容性
当前仓库已验证：
- 可复用 workflow 模型可行
- Dev GitOps PR 自动合并可行
- Prod 人工审批流程可行

因此可将当前仓库作为创建 `platform-cicd` 的种子来源。
