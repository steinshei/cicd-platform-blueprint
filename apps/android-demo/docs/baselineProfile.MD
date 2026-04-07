### 生成baseline-prof和startup-prof 优化冷启动和卡帧

|文件名|优化目标|作用时机|
|---|---|---|
|baseline-prof.txt |运行时流畅度|减少滑动卡顿（Jank）、加速页面跳转。
|startup-prof.txt |极致启动速度 |专门针对 Application 到第一帧渲染之间的 DEX 布局优化。

./gradlew clean

./gradlew :app:generateBaselineProfile --no-build-cache

### CI（GitHub Actions）

- **工作流**：仓库根目录 [`.github/workflows/android-demo-baseline-profile.yaml`](../../../.github/workflows/android-demo-baseline-profile.yaml)（路径以仓库根为准）。
- **何时运行**：向 `develop` / `main` / `release/**` 发起 PR 或推送，且变更落在 `apps/android-demo/**` 或上述 workflow 本身时。
- **做什么**：
  1. 无模拟器：`:app:assembleRelease`、`:benchmark:assembleBenchmarkBenchmark`（须写全名；`:benchmark:assembleBenchmark` 会与多个 variant 前缀冲突导致 Gradle 报错），尽快发现编译问题。
  2. 在 `ubuntu-latest` 上用模拟器执行 `:app:generateBaselineProfile --no-build-cache`，再对 `app/src/main/baselineProfiles/` 做 `git diff`；与已提交内容不一致则失败。
- **CI 排障（adb `device offline` / 启动慢）**：可复用 workflow 在 `android-emulator-runner` 前执行 [KVM udev 步骤](https://github.com/ReactiveCircus/android-emulator-runner#running-hardware-accelerated-emulators-on-linux-runners)，并将 `emulator-boot-timeout` 设为 900 秒；仍不稳定时可换更大规格 Linux runner 或自托管。
- **`gradlew` 找不到**：该 Action 会把 `script` **按行**拆成多次独立的 `sh -c`，目录不跨行保留；可复用 workflow 已设置 `working-directory` 为 Gradle 根目录（如 `apps/android-demo`），并把 Gradle / `git diff` 各写为单行命令。
- **`The process '/usr/bin/sh' failed with exit code 1`**：在日志里向上查找 Gradle 与 `git diff`。若有 `FAILURE: Build failed` 等，属构建/测试问题；若 Gradle 成功、出现 `::error::Baseline profile` 或 `git diff` 输出，属**已提交的 profile 与 CI 生成结果不一致**，请在本地再生并提交 `app/src/main/baselineProfiles/*.txt`。
- **本地对齐**：在 `apps/android-demo` 下执行与上相同的 `./gradlew :app:generateBaselineProfile --no-build-cache`，将生成的 `baseline-prof.txt` / `startup-prof.txt` 一并提交。

可复用逻辑在 [`.github/workflows/reusable-android-baseline-profile.yml`](../../../.github/workflows/reusable-android-baseline-profile.yml)。发布到组织平台仓时可将同文件合并进 `steinshei/platform-cicd` 并打新标签，入口 workflow 中把 `uses: ./.github/workflows/reusable-android-baseline-profile.yml` 改为 `uses: steinshei/platform-cicd/.github/workflows/reusable-android-baseline-profile.yml@<tag>`。
