# 多仓推广 PoC

## 目标
验证多仓 CI/CD 模型：业务仓仅保留轻量入口 workflow，并调用平台仓提供的可复用 workflow。

## 本分支新增内容
- `.github/workflows/platform-ci-poc.yaml`
  - 手动触发（`workflow_dispatch`）
  - 通过仓库引用调用可复用 workflow：
    - `uses: steinshei/platform-cicd/.github/workflows/reusable-ci.yml@v1.1`

## 为什么该 PoC 是安全的
- 不会替换现有 `ci-main` 或 `security-sast`
- 不会在 push/PR 上自动触发
- 仅在 Actions 页面手动触发时运行

## 在当前仓库的测试方式
1. 推送当前分支并创建到 `main` 的 PR。
2. 在 GitHub Actions 中手动运行 `platform-ci-poc`。
3. 先使用默认参数（`sample-service`）。
4. 验证作业通过：构建、测试、扫描、签名、制品证明（attestation）。

## 标准多仓迁移模式
1. 创建组织级平台仓（例如 `org/platform-cicd`）。
2. 将共享可复用 workflow 迁移到平台仓，并用标签管理版本（`v1`、`v1.1`）。
3. 每个业务仓仅保留轻量入口 workflow：
   - `uses: org/platform-cicd/.github/workflows/reusable-ci.yml@v1.1`
4. 在组织层统一执行规则集和必需检查。
5. 先小范围试点（3-5 仓），再规模化推广。

## PoC 后续动作
将 PoC 中的 `uses:` 目标替换为真实平台仓地址，并改为固定版本标签引用。
