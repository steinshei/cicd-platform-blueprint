# 多仓迁移检查清单

## 阶段 0：平台仓准备
- [x] 创建 `steinshei/platform-cicd`
- [x] 将当前仓库中的可复用 workflow 迁移到平台仓
- [x] 给平台 workflow 打 `v1` 标签
- [x] 输出业务仓接入说明文档

## 阶段 1：业务仓试点（2-3 个）
- [x] 将本地重型 workflow 替换为轻量入口 workflow
- [x] `uses:` 指向 `platform-cicd@v1.1`
- [x] 保持分支保护开启
- [x] 配置 `staging/prod` 环境必需审批人

## 阶段 2：单仓功能验收
- [x] PR 检查通过（ci/security）
- [x] 合并到 `main` 后触发 CI 流水线
- [x] 自动创建 `deploy(dev)` PR
- [x] `deploy(dev)` PR 检查通过并自动合并
- [x] 无部署循环（防循环条件已验证）
- [x] `promote` 生成 `prod` PR，且必须手动合并

## 阶段 3：安全验收
- [x] CodeQL 运行成功（`go` 使用 `autobuild`，`actions` 使用 `none`）
- [x] Semgrep 通过，或已记录可接受的误报
- [x] Trivy 门禁行为符合预期
- [x] 成功产出 SBOM
- [x] Cosign 签名链路验证通过（key 或 keyless）

## 阶段 4：运行验收
- [x] DORA 事件脚本可产出记录
- [x] 回滚路径有文档且可演练
- [x] service catalog 含值班 / runbook 链接

## 阶段 5：规模化推广
- [ ] 分批迁移剩余仓库
- [ ] 删除业务仓中重复的本地 workflow 逻辑
- [ ] 业务仓仅保留标准入口模板
- [ ] 在 GitHub Projects 跟踪迁移进度（可选，偏项目管理）

## 项目级验收标准
- [ ] 至少 3 个试点仓库稳定运行 1 周
- [ ] Dev 发布流无需人工合并
- [ ] Staging/Prod 仍保持人工审批
- [ ] 新仓接入平均耗时 <= 1 天
- [ ] 迁移后无关键安全门禁回退
