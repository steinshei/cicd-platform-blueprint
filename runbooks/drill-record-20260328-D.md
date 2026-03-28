# 发布演练记录 D（2026-03-28）

## 目标
- 验证第 2 项流程：`release/* -> main` 全链路可执行。
- 保留审计证据，便于回灌 `develop` 后追踪。

## 变更内容
- 本次仅新增演练记录文件，不涉及业务代码。
- 分支：`release/drill-20260328-d`
- 基线：`origin/develop`

## 执行步骤
1. 创建 `release/drill-20260328-d` 并提交最小变更。
2. 发起 PR：`release/drill-20260328-d -> main`。
3. 等待 required checks 通过并完成 main 审批。
4. 合并后执行 promote（staging/prod 按审批门禁）。
5. 验证完成后执行 `main -> develop` 回灌。

## 验收记录
- 状态：进行中
- 备注：本文件用于触发和记录本次演练。
