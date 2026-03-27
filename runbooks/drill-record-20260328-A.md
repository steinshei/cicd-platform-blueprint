# 钻探记录 A（镜像仓库不可用）

- 日期：2026-03-28
- 服务：sample-service
- 环境：sample-service-dev
- 钻探类型：A 无法访问注册表
- 指挥官：steinshei

## 时间线
- 检测时间：2026-03-28 04:55:32 +0800
- 救援开始时间：2026-03-28 04:55:33 +0800
- 恢复完成时间：2026-03-28 04:55:33 +0800
- 平均修复时间：1 秒

## 发生了什么
- 触发动作：`kubectl argo rollouts set image sample-service sample-service=invalid.registry.local/sample-service:broken -n sample-service-dev`
- 观察到的影响：Rollout 状态从 Healthy 进入异常推进态（坏镜像不可拉取）。
- 推广状态：已触发并完成回滚恢复。

## 恢复
- 恢复指令（若干条）：
  - `kubectl argo rollouts undo sample-service -n sample-service-dev`
  - `kubectl argo rollouts get rollout sample-service -n sample-service-dev`
- 回退修订/标签：回退到上一稳定修订（stable）。
- 验证证据：恢复后 `Status: ✔ Healthy`，`Desired/Updated/Ready/Available = 4/4/4/4`。

## 根本原因及预防措施
- 根本原因：镜像仓库地址不可达导致新版本镜像拉取失败。
- 为何未能及早发现：仓库可用性未做前置探针检查。
- 任务清单（负责人 + 完成日期）：
  - 在发布前增加镜像可拉取预检（平台团队，2026-04-05）
  - 将镜像仓库异常告警接入值班通道（平台团队，2026-04-08）
