### 生成baseline-prof和startup-prof 优化冷启动和卡帧

|文件名|优化目标|作用时机|
|---|---|---|
|baseline-prof.txt |运行时流畅度|减少滑动卡顿（Jank）、加速页面跳转。
|startup-prof.txt |极致启动速度 |专门针对 Application 到第一帧渲染之间的 DEX 布局优化。

./gradlew clean  

./gradlew :app:generateBaselineProfile --no-build-cache