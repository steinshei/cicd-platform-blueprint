# 集群侧 Phase2 执行手册（Rollouts + Kyverno + 演练）

## 目标

在可用 Kubernetes 集群完成：

1. Argo Rollouts 金丝雀发布（5 -> 20 -> 50 -> 100）
2. Kyverno 分层策略启用
3. 三类故障演练并记录恢复时间

## 1) Rollouts 启用

1. 安装 Argo Rollouts 控制器。
2. 应用 Helm 模板中的 Rollout 资源。
3. 确认 `deploy/helm/sample-service/values.yaml` 的 `rollout.steps` 为 5/20/50/100。
4. 使用以下命令观测推进：

```bash
kubectl argo rollouts get rollout sample-service -n sample-service --watch
```

## 2) Kyverno 策略启用顺序

1. `disallow-latest-tag.yaml`
2. `require-resources.yaml`
3. `verify-image-signature.yaml`
4. `platform-namespace-exception.yaml`（平台命名空间例外）

建议先 `Audit` 再切 `Enforce`，逐步收敛误报。

## 3) 故障演练清单

### 演练 A：镜像仓库不可用

- 方式：将镜像仓库地址改为无效域名
- 预期：Rollout 卡在镜像拉取失败，触发回滚/人工回滚
- 验收：恢复时间记录到 runbook（目标 < 5 分钟）

### 演练 B：配置错误

- 方式：注入错误配置导致应用启动失败
- 预期：探针失败，Rollout 暂停或回滚
- 验收：恢复到上一版本，服务 SLO 恢复

### 演练 C：探针失败

- 方式：临时修改健康检查路径
- 预期：新版本不可用，按策略中断推进
- 验收：自动/手动回滚可完成

## 4) 演练记录模板

- 日期：
- 服务：
- 演练类型（A/B/C）：
- 检测时间：
- 恢复时间：
- MTTR：
- 根因：
- 后续改进项（owner + due date）：
