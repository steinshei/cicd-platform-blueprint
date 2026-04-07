plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // 确保这一行存在，且没有被注释
    id("androidx.baselineprofile")
}

android {
    namespace = "com.example.androiddemo"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.androiddemo"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        getByName("release") {
            // 关键：告诉 app 如果在依赖项中找不到 release，就去找 benchmark
            matchingFallbacks += listOf("benchmark")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
    }

}

baselineProfile {
    // 或者合并到特定的 SourceSet
    mergeIntoMain = true

    // 关键：显式指定保存到源码目录（有些版本需要这个开关）
    saveInSrc = true

    // 如果插件还是找不到地方，我们可以手动指定输出目录名
    // 这样它会尝试生成在 src/main/baselineProfiles/
    baselineProfileOutputDir = "baselineProfiles"
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation(libs.profileinstaller)
    baselineProfile(project(":benchmark"))
}
