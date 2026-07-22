import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val signingEnvironmentVariables =
    mapOf(
        "storePassword" to "ANDROID_UPLOAD_STORE_PASSWORD",
        "keyPassword" to "ANDROID_UPLOAD_KEY_PASSWORD",
        "keyAlias" to "ANDROID_UPLOAD_KEY_ALIAS",
        "storeFile" to "ANDROID_UPLOAD_STORE_FILE",
    )
val environmentSigningConfigured =
    signingEnvironmentVariables.values.any { name ->
        !System.getenv(name).isNullOrBlank()
    }
val releaseSigningConfigured = keystorePropertiesFile.isFile || environmentSigningConfigured

if (keystorePropertiesFile.isFile) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

fun requiredSigningProperty(name: String): String {
    val environmentName = signingEnvironmentVariables.getValue(name)
    return System.getenv(environmentName)?.takeIf(String::isNotEmpty)
        ?: keystoreProperties.getProperty(name)?.trim()?.takeIf(String::isNotEmpty)
        ?: throw GradleException(
            "Missing Android release signing value '$name'. Set $environmentName " +
                "or provide it in ${keystorePropertiesFile.absolutePath}.",
        )
}

val releaseKeystoreFile =
    if (releaseSigningConfigured) {
        rootProject.file(requiredSigningProperty("storeFile"))
    } else {
        null
    }

android {
    namespace = "ir.emadkarimi.darutakey"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ir.emadkarimi.darutakey"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = requiredSigningProperty("keyAlias")
                keyPassword = requiredSigningProperty("keyPassword")
                storeFile = releaseKeystoreFile
                storePassword = requiredSigningProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val verifyReleaseSigning by tasks.registering {
    group = "verification"
    description = "Verifies that Android release signing material is present and valid."

    doLast {
        if (!releaseSigningConfigured) {
            throw GradleException(
                "Release signing is not configured. Copy android/key.properties.example " +
                    "to android/key.properties or provide the ANDROID_UPLOAD_* environment variables.",
            )
        }

        if (releaseKeystoreFile?.isFile != true) {
            throw GradleException(
                "Release keystore was not found at ${releaseKeystoreFile?.absolutePath}.",
            )
        }
    }
}

tasks.matching { task ->
    task.name == "assembleRelease" || task.name == "bundleRelease"
}.configureEach {
    dependsOn(verifyReleaseSigning)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
