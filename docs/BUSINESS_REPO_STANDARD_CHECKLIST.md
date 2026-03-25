# 业务仓接入标准清单（1 页）

适用对象：接入 `steinshei/platform-cicd` 的单业务仓。

## 1. 平台 workflow 引用

- [ ] `ci-main` 使用 `reusable-ci.yml@v1.1`
- [ ] `security-sast-platform` 使用 `reusable-security-sast.yml@v1.1`
- [ ] `ci-main` 中 `update-dev-gitops` 使用 `reusable-deploy-dev.yml@v1.1`
- [ ] `promote` 使用 `reusable-promote.yml@v1.1`
- [ ] 禁止引用 `@main`

## 2. 分支保护与环境

- [ ] main 保护开启，要求必须通过以下检查：
  - `pipeline / validate-build-scan`
  - `security / semgrep`
  - `security / codeql (actions, none)`
  - `security / codeql (go, autobuild)`
- [ ] Environments 已创建：`dev` / `staging` / `prod`
- [ ] `staging` / `prod` 已配置 required reviewers
- [ ] `CI_BOT_TOKEN` 已配置（用于 dev PR 自动合并）

## 3. 发布行为

- [ ] `dev` 走自动推进（deploy PR 自动合并）
- [ ] `staging/prod` 必须审批后手动合并
- [ ] 不存在 deploy(dev) 循环 PR
- [ ] 有回滚路径并在 runbook 中可执行

## 4. DORA 与审计

- [ ] 工作流会产出 `dora-event-*` artifact
- [ ] `dora-weekly-report` 可手动触发并输出周报
- [ ] 指标包含：Lead Time、Deployment Frequency、MTTR、Change Failure Rate

## 5. 新服务接入

- [ ] `./scripts/onboard_service.sh <service>` 可生成：
  - 应用骨架 `apps/<service>/`
  - 入口 workflow `.github/workflows/<service>-ci.yaml`
  - GitOps values `gitops/environments/*/<service>-values.yaml`
  - catalog `service-catalog/<service>.yaml`
