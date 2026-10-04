import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Local secrets only. Debug builds do not require release credentials.
val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
val releasePropertiesLoaded = runCatching {
    if (releasePropertiesFile.isFile) {
        releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
    }
}.isSuccess
val releaseFields = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
val releaseCredentialsPresent = releasePropertiesLoaded && releaseFields.all {
    !releaseProperties.getProperty(it).isNullOrBlank()
}
val releaseKeystore = releaseProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }?.let { rootProject.file(it) }

gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release", ignoreCase = true) }) {
        if (!releaseCredentialsPresent || releaseKeystore?.isFile != true) {
            throw GradleException(
                "Release signing credentials missing or invalid. Create android/key.properties " +
                    "with storePassword, keyPassword, keyAlias and storeFile pointing to your " +
                    "existing release keystore. Release builds never use debug signing."
            )
        }
    }
}

android {
    namespace = "com.veles.arrowword.arrowword"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.veles.arrowword.arrowword"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseCredentialsPresent) {
                storeFile = releaseKeystore
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
