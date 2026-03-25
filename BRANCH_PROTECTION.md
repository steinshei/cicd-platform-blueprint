# 分支与环境保护基线（GitFlow-lite）

## 分支保护

### `main`（稳定线）

- 必须通过 Pull Request 才能合并
- 仅允许 `release/*` 或 `hotfix/*` 来源分支（由 `pr-guard` 强制）
- 必须通过状态检查：
  - `pipeline / validate-build-scan`
  - `security / semgrep`
  - `security / codeql (actions, none)`
  - `security / codeql (go, autobuild)`
  - `pr-guard / main-source-guard`
- 要求分支与目标分支保持最新
- 禁止强推与删除分支

### `develop`（开发集成线）

- 必须通过 Pull Request 才能合并
- 必须通过状态检查：
  - `pipeline / validate-build-scan`
  - `security / semgrep`
  - `security / codeql (actions, none)`
  - `security / codeql (go, autobuild)`
- 要求分支与目标分支保持最新
- 禁止强推与删除分支

## 环境保护

- `dev`：无需审批人（自动推进）
- `staging`：至少 1 位审批人
- `prod`：至少 2 位审批人

以上配置用于保证发布审批门禁和部署审计可追溯。
