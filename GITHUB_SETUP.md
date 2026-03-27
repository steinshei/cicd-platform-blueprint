# GitHub 仓库配置（可执行）

目标仓库：`steinshei/cicd-platform-blueprint`

## 1. 生成管理员 Token

你需要一个可管理仓库设置的 Token。

- Classic token：`repo`、`workflow`、`admin:repo_hook`
- Fine-grained token：
  - Repository: `cicd-platform-blueprint`
  - Permissions:
    - Contents: Read and write
    - Actions: Read and write
    - Administration: Read and write

## 2. 一键执行基础配置

```bash
cd /Users/gavin/work_space/cicd_project
export GITHUB_TOKEN='<你的token>'
./scripts/setup_github_repo.sh steinshei cicd-platform-blueprint
```

这个脚本会做：
- 自动创建 `develop` 分支（若不存在）
- `main` 与 `develop` 分支保护
- 创建 `dev` / `staging` / `prod` 三个 environment

## 3. 在 UI 补全审批人

GitHub -> Settings -> Environments：

- `dev`: 不设审批人
- `staging`: 至少 1 位审批人
- `prod`: 至少 2 位审批人

## 4. 配置仓库 Secrets

GitHub -> Settings -> Secrets and variables -> Actions：

- 必需：`CI_BOT_TOKEN`（用于 `develop` 上 `deploy(dev)` PR 自动合并）
- 可选：`COSIGN_PRIVATE_KEY`
- 可选：`COSIGN_PASSWORD`

GitHub -> Settings -> Secrets and variables -> Actions -> Variables：

- 必需：`AUTO_PR_REVIEWERS`（逗号分隔审核人用户名，例如 `alice,bob`）

GitHub -> Settings -> General：

- 开启：`Allow auto-merge`

说明：
- GHCR 推送默认使用 `GITHUB_TOKEN`，不再强制 `REGISTRY_USERNAME/REGISTRY_PASSWORD`。
- 未配置 Cosign 私钥时，流水线会走 OIDC keyless 签名。

## 5. 验证

- `feature/*` push：应自动创建/更新到 `develop` 的 PR，并自动请求审核人
- `develop` 默认不强制审批；checks 通过：PR 应自动合并到 `develop`
- 合并到 `develop`：应自动创建并自动合并 `deploy(dev)` PR，更新 `gitops/environments/dev/sample-service-values.yaml`
- 从 `release/*` 或 `main` 手工触发 `promote`：先过 `staging` 审批，再过 `prod` 审批

main 分支推荐必需检查：
- `pipeline / validate-build-scan`
- `security / semgrep`
- `security / codeql (actions, none)`
- `security / codeql (go, autobuild)`
- `pr-guard / main-source-guard (pull_request)`

develop 分支推荐必需检查：
- `pipeline / validate-build-scan`
- `security / semgrep`
- `security / codeql (actions, none)`
- `security / codeql (go, autobuild)`

可执行校验：

```bash
export GITHUB_TOKEN='<你的token>'
./scripts/verify_required_checks.sh steinshei cicd-platform-blueprint
```
