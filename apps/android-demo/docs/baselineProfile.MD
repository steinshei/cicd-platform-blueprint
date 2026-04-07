### 生成 baseline-prof 和 startup-prof（优化冷启动与卡顿）

| 文件名 | 优化目标 | 作用时机 |
|---|---|---|
| baseline-prof.txt | 运行时流畅度 | 减少滑动卡顿（Jank）、加速页面跳转 |
| startup-prof.txt | 启动速度 | 针对 Application 到第一帧渲染之间的 DEX 布局优化 |

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
  - 通过可复用工作流 [`.github/workflows/reusable-android-macrobenchmark-self-hosted.yml`](../../../.github/workflows/reusable-android-macrobenchmark-self-hosted.yml)

  - 默认执行任务：`:benchmark:connectedBenchmarkReleaseAndroidTest`
  - 在模拟器环境默认添加：`-Pandroid.testInstrumentationRunnerArguments.androidx.benchmark.suppressErrors=EMULATOR`

  - 默认 Runner 标签：`["self-hosted","linux","x64","android"]`（按你的机器实际注册标签调整）

### 闭环建议

1. 本地：生成 Baseline Profile 并提交。
2. 云端：编译 + 单测基础门禁。
3. 本地 self-hosted：Macrobenchmark 启动性能验证。
4. 达标再发布；不达标回修并重测。
