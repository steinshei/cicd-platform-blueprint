# 钻探记录 C（探针失败）

- 日期：2026-03-28
- 服务：sample-service
- 环境：sample-service-dev
- 钻探类型：C 探测失败
- 指挥官：steinshei

## 时间线
- 检测时间：2026-03-28 04:56:20 +0800
- 救援开始时间：2026-03-28 04:56:21 +0800
- 恢复完成时间：2026-03-28 04:56:21 +0800
- 平均修复时间：1 秒

## 发生了什么
- 触发动作：将 readiness 路径改为错误值：
  - `kubectl -n sample-service-dev patch rollout sample-service --type='json' -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/wrong-healthz\"}]'`
- 观察到的影响：Rollout 偏离 Healthy，进入失败推进路径。
- 推广状态：已触发并完成回滚恢复。

## 恢复
- 恢复指令（若干条）：
  - `kubectl argo rollouts undo sample-service -n sample-service-dev`
  - `kubectl argo rollouts get rollout sample-service -n sample-service-dev`
- 回退修订/标签：回退到上一稳定修订（stable）。
- 验证证据：恢复后 `Status: ✔ Healthy`，Pods 全部 `Running`。

## 根本原因及预防措施
- 根本原因：健康检查路径配置错误导致 readiness 失败。
- 为何未能及早发现：探针参数缺少变更前自动校验。
- 任务清单（负责人 + 完成日期）：
  - 增加 readiness/liveness 参数静态校验（平台团队，2026-04-06）
  - 在发布流程加入探针回归检查（平台团队，2026-04-09）
