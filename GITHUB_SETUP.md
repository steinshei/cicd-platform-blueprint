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
- `main` 分支保护
- 创建 `dev` / `staging` / `prod` 三个 environment

## 3. 在 UI 补全审批人

GitHub -> Settings -> Environments：

- `dev`: 不设审批人
- `staging`: 至少 1 位审批人
- `prod`: 至少 2 位审批人

## 4. 配置仓库 Secrets

GitHub -> Settings -> Secrets and variables -> Actions：

- 可选：`COSIGN_PRIVATE_KEY`
- 可选：`COSIGN_PASSWORD`

说明：
- GHCR 推送默认使用 `GITHUB_TOKEN`，不再强制 `REGISTRY_USERNAME/REGISTRY_PASSWORD`。
- 未配置 Cosign 私钥时，流水线会走 OIDC keyless 签名。

## 5. 验证

- 提交一个 PR：应触发 `ci-main` + `security-sast`
- 合并到 `main`：应自动创建 GitOps PR，更新 `gitops/environments/dev/sample-service-values.yaml`
- 手工触发 `promote`：先过 `staging` 审批，再过 `prod` 审批
