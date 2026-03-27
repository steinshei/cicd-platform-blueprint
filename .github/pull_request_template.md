## PR Target Rule

- 日常功能开发请使用：`feature/* -> develop`
- 发布稳定后再使用：`release/* -> main`
- 生产修复使用：`hotfix/* -> main`（并回灌 `develop`）

## Checklist

- [ ] 我确认目标分支选择正确（不是把 `feature/*` 直接合到 `main`）
- [ ] 已通过必需 checks（pipeline + security）
- [ ] 如涉及发布，已按 `develop -> release/* -> main` 路径执行
