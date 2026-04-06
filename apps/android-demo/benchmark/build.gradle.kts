import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.test)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.androidx.baselineprofile)
}

android {
    namespace = "com.example.androiddemo.benchmark"
    compileSdk = 34

    // 关键：告诉插件，这个测试模块是为 :app 服务的
    targetProjectPath = ":app"

    defaultConfig {
        minSdk = 24
        targetSdk = 34
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // 这一段可以确保 Gradle 自动下载并使用正确的 JDK
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    buildTypes {
        // 这里的名称必须与上面 testBuildType 一致
        create("benchmark") {
            isDebuggable = false
            // Baseline Profile 需要在开启混淆的情况下采集才最精准
            isMinifyEnabled = true
            matchingFallbacks += listOf("release")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "benchmark-rules.pro"
            )
            // 这里的签名必须和 app 的 release 保持一致，或者都用 debug 签名
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    targetProjectPath = ":app"
    experimentalProperties["android.experimental.self-instrumenting"] = true

    buildFeatures {
        buildConfig = false
    }
}

dependencies {

    // 解决 R8 找不到 ErrorProne 注解的问题
    compileOnly("com.google.errorprone:error_prone_annotations:2.18.0")

    implementation(libs.profileinstaller)
    implementation(libs.macrobenchmark)
    implementation(libs.uiautomator)
    implementation(libs.android.test.runner)
}

//androidComponents {
//  beforeVariants(selector().all()) {
//    it.enable = it.buildType == "benchmark"
//  }
//}
