# 1. 保留所有 Benchmark 相关的注解和测试类
-keepattributes *Annotation*
-keep class androidx.benchmark.** { *; }
-keep class androidx.test.** { *; }

# 2. 确保 MacrobenchmarkRule 和 BaselineProfileRule 不被移除
-keep class androidx.benchmark.macro.** { *; }
-keep class androidx.benchmark.macro.junit4.** { *; }

# 3. 保留 UIAutomator 相关，因为它需要通过反射查找 View
-keep class androidx.test.uiautomator.** { *; }

# 4. 关键：保留你的测试代码（Generator 类）
# 替换为你的实际包名
-keep class com.github.steinshei.benchmark.** { *; }

# 5. 处理 Kotlin 协程和元数据（如果使用了）
-keep class kotlin.Metadata { *; }

# 防止 R8 移除常用的 AndroidX 资源 ID
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 保护你的 Activity 和其生命周期方法，不让它们被 D8/R8 优化掉
-keep class com.example.androiddemo.** { *; }

# 允许混淆，但保留行号（方便在生成 Profile 时追踪方法路径）
-keepattributes SourceFile,LineNumberTable