### 平台仓下沉优化方案（目标：新业务仓“一条命令接入”）

#### Summary
以你选择的 **CLI 一键接入** 为主线，把当前业务仓里“重复且易错”的能力下沉到 `platform-cicd`，业务仓只保留最薄配置层。  
目标状态：新业务仓仅需 `service-catalog.yaml + 1 个入口 workflow + 1 条 bootstrap 命令`，其余由平台仓统一生成和治理。

#### Key Changes
1. **下沉仓库治理到平台 CLI（最高优先级）**
- 在 `platform-cicd` 提供 `scripts/bootstrap_repo.sh <owner> <repo> --mode gitflow-lite`。
- 统一自动配置：
  - 创建/校验分支：`develop`
  - 分支保护（`main/develop`）
  - 必需 checks 注入与校验
  - Environments：`dev/staging/prod`
  - 仓库变量检查：`AUTO_PR_REVIEWERS`
  - 仓库开关检查：`Allow auto-merge`
- 业务仓删除本地 `setup_github_repo.sh`/`verify_required_checks.sh` 的主逻辑，仅保留调用平台仓脚本。

2. **下沉 workflow 入口模板到平台仓**
- 在 `platform-cicd` 提供统一入口模板生成器：`scripts/render_repo_workflows.sh`。
- 生成并维护 4 个标准入口：
  - `ci-main.yaml`
  - `security-sast-platform.yaml`
  - `feature-auto-pr.yaml`
  - `pr-guard.yaml`
- 业务仓只保留 `uses: steinshei/platform-cicd/...@vX.Y` 与少量参数（service 名、路径）。
- 版本固定到 tag（如 `@v1.2`），禁止 `@main`。

3. **下沉服务接入脚手架为平台命令**
- 把 `onboard_service.sh` 下沉到 `platform-cicd` 并产品化为：
  - `bootstrap_service.sh <service> --repo <owner/repo> --lang go --branch develop`
- 输出最小化：
  - `apps/<service>/`（可选 skeleton）
  - `gitops/environments/*/<service>-values.yaml`
  - `service-catalog/<service>.yaml`
- 业务仓不再维护一份独立 onboarding 脚本。

4. **统一并冻结“检查名契约”**
- 在平台仓定义单一 `required-checks.json`（main/develop 两套）。
- `bootstrap_repo.sh` 与 `verify_required_checks.sh`都读取同一契约源。
- 修复并固定 `pr-guard` 检查名，避免再次出现 `Expected` 卡死。

5. **把“高频手工项”改成平台预检报告**
- 平台命令增加 `doctor`：
  - 输出 PASS/FAIL 清单（权限、secrets、variables、checks 对齐、branch protection）。
- 新仓接入改为：
  1) `bootstrap_repo.sh`
  2) `doctor`
  3) 提交一次测试 PR 即完成验收。

#### Public Interfaces / Standards
- 平台仓新增接口：
  - `scripts/bootstrap_repo.sh`
  - `scripts/doctor_repo.sh`
  - `scripts/bootstrap_service.sh`
  - `contracts/required-checks.json`
- 业务仓保留的最小接口：
  - `service-catalog/*.yaml`
  - `gitops/environments/*/*-values.yaml`
  - 轻量入口 workflow（仅 `uses + with`）
- 版本策略：
  - 所有业务仓统一引用 `platform-cicd@v1.2`（后续小步升级到 `v1.3` 等）。

#### Test Plan
1. 新建一个测试仓执行 `bootstrap_repo.sh`，验证 `main/develop` 保护和 checks 全对齐（`doctor` 全绿）。
2. 新仓推送 `feature/*`，自动建 PR 到 `develop`，checks 通过后自动合并。
3. 合并到 `develop` 后自动触发 `deploy(dev)`，不出现 `Expected` 检查卡死。
4. 走一轮 `develop -> release/* -> main -> backfill develop`，验证主流程闭环。
5. 用 `bootstrap_service.sh` 新增一个服务，1 天内跑通所有 required checks。

#### Assumptions
- 仍采用 `GitFlow-lite`：`feature/* -> develop -> release/* -> main`。
- 继续使用 `platform-cicd` 作为唯一平台仓，业务仓只消费版本标签。
- 组织级 GitHub App 暂不引入，本轮以 CLI 自动化为主，后续可升级。
