### 生成 baseline-prof 和 startup-prof（优化冷启动与卡顿）

| 文件名 | 优化目标 | 作用时机 |
|---|---|---|
| baseline-prof.txt | 运行时流畅度 | 减少滑动卡顿（Jank）、加速页面跳转 |
| startup-prof.txt | 启动速度 | 针对 Application 到第一帧渲染之间的 DEX 布局优化|
|

本地生成：

./gradlew clean
./gradlew :app:generateBaselineProfile --no-build-cache

### CI（按最新闭环）

- **工作流**：仓库根目录 [`.github/workflows/android-demo-baseline-profile.yaml`](../../../.github/workflows/android-demo-baseline-profile.yaml)。
- **触发**：`develop` / `main` / `release/**` 的 PR、push，以及手动触发（`workflow_dispatch`）。
- **云端 CI（GitHub-hosted）**：只做基础门禁，不跑模拟器。
  1. `:app:assembleRelease`
  2. `:benchmark:assembleBenchmarkBenchmark`
  3. `:app:testDebugUnitTest`
- **本地 CI（Self-hosted Runner）**：使用本地模拟器运行 Macrobenchmark（`benchmark` 模块）。
  - 通过平台仓可复用工作流：`steinshei/platform-cicd/.github/workflows/reusable-android-macrobenchmark-self-hosted.yml@v1.8`

  - 默认执行任务：`:benchmark:connectedBenchmarkReleaseAndroidTest`
  - 在模拟器环境默认添加：`-Pandroid.testInstrumentationRunnerArguments.androidx.benchmark.suppressErrors=EMULATOR`

  - 默认 Runner 标签：`["self-hosted"]`（先保证可领取，再按需收紧到 `macOS/ARM64` 等）

### 闭环建议

1. 本地：生成 Baseline Profile 并提交。
2. 云端：编译 + 单测基础门禁。
3. 本地 self-hosted：Macrobenchmark 启动性能验证。
4. 达标再发布；不达标回修并重测。


### 打包产物（GitHub Artifacts）

- **工作流**：仓库根目录 [`.github/workflows/android-demo-package.yaml`](../../../.github/workflows/android-demo-package.yaml)
- **触发方式**：
  1. 手动触发（`workflow_dispatch`）
  2. 推送 tag：`android-demo-v*`
- **产物内容**：
  - `app/build/outputs/apk/release/*.apk`
  - `app/build/outputs/bundle/release/*.aab`
- **下载位置**：GitHub 仓库 `Actions` -> `android-demo-package` -> 选择运行记录 -> `Artifacts`（默认保留 14 天）
- **实现方式**：业务仓入口 workflow 调用平台仓 `steinshei/platform-cicd/.github/workflows/reusable-android-package.yml@v1.8`


### 签名打包（手动触发）

- **工作流**：仓库根目录 [`.github/workflows/android-demo-package-signed.yaml`](../../../.github/workflows/android-demo-package-signed.yaml)
- **触发方式**：`workflow_dispatch`
- **仓库 Secrets（必填）**：
  - `ANDROID_KEYSTORE_BASE64`（keystore 文件的 base64）
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
- **产物**：
  - 已签名 APK（来自 `r0adkll/sign-android-release` 输出）
  - Release AAB（用于后续渠道发布）

### 上线前最终核对清单（5 条）

1. **Baseline Profile 已更新并提交**  
   在 `apps/android-demo` 下执行过：`./gradlew :app:generateBaselineProfile --no-build-cache`，并确认 `app/src/main/baselineProfiles/*.txt` 已入库。

2. **云端门禁全绿**  
   `android-demo-ci` 的 `cloud-gate`（编译 + 单测）在目标分支对应 PR 中通过。

3. **本地 self-hosted 宏基准通过**  
   `local-macrobenchmark / run-macrobenchmark` 成功执行；若使用模拟器，已显式使用 `suppressErrors=EMULATOR` 且结果符合团队阈值。

4. **打包产物可下载可安装**  
   `android-demo-package`（或后续签名流）产出 Artifact，APK/AAB 可在 Actions 页面下载并完成安装验证。

5. **分支保护与必需检查已对齐**  
   仓库 required checks 已覆盖当前实际依赖链路（至少包含 Android 门禁关键检查），避免“流程通过但无法合并”或“漏检直接合并”。
