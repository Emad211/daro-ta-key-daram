import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val releaseSigningConfigured = keystorePropertiesFile.isFile

if (releaseSigningConfigured) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

fun requiredSigningProperty(name: String): String =
    keystoreProperties.getProperty(name)?.trim()?.takeIf(String::isNotEmpty)
        ?: throw GradleException(
            "Missing '$name' in ${keystorePropertiesFile.absolutePath}.",
        )

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
                    "to android/key.properties and provide an ignored upload keystore.",
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
