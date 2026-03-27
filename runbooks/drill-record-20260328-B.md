# 钻探记录 B（配置错误）

- 日期：2026-03-28
- 服务：sample-service
- 环境：sample-service-dev
- 钻探类型：B 配置错误
- 指挥官：steinshei

## 时间线
- 检测时间：2026-03-28 04:55:57 +0800
- 救援开始时间：2026-03-28 04:55:58 +0800
- 恢复完成时间：2026-03-28 04:55:58 +0800
- 平均修复时间：1 秒

## 发生了什么
- 触发动作：将容器启动命令临时改为不存在的二进制：
  - `kubectl -n sample-service-dev patch rollout sample-service --type='json' -p='[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/command\",\"value\":[\"/nonexistent-binary\"]}]'`
- 观察到的影响：Rollout 偏离 Healthy（进入异常推进/不可用状态）。
- 推广状态：已触发并完成回滚恢复。

## 恢复
- 恢复指令（若干条）：
  - `kubectl argo rollouts undo sample-service -n sample-service-dev`
  - `kubectl argo rollouts get rollout sample-service -n sample-service-dev`
- 回退修订/标签：回退到上一稳定修订（stable）。
- 验证证据：恢复后 `Status: ✔ Healthy`。

## 根本原因及预防措施
- 根本原因：错误配置导致容器无法按预期启动。
- 为何未能及早发现：变更前缺少对关键启动参数的策略校验。
- 任务清单（负责人 + 完成日期）：
  - 为关键启动参数增加策略校验（平台团队，2026-04-06）
  - 在发布流水线增加 rollout smoke check（平台团队，2026-04-08）
