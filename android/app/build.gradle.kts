import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Der eigene Signaturschlüssel, falls es einen gibt.
//
// android/key.properties steht in .gitignore und liegt nur auf dem Rechner
// des Besitzers; im Workflow kommen dieselben Werte aus Secrets. Fehlt
// beides, wird mit dem Debug-Schlüssel gebaut — sonst wäre der Bau für
// jeden kaputt, der den Schlüssel nicht hat.
val keyProperties = Properties().apply {
    val datei = rootProject.file("key.properties")
    if (datei.exists()) datei.inputStream().use { load(it) }
}

fun signaturWert(name: String, umgebung: String): String? =
    keyProperties.getProperty(name) ?: System.getenv(umgebung)

val keystoreDatei: String? = signaturWert("storeFile", "ANDROID_KEYSTORE_FILE")
val hatEigenenSchluessel: Boolean =
    keystoreDatei != null && rootProject.file(keystoreDatei).exists()

android {
    namespace = "de.susasek.sprungkalender"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Wird von flutter_local_notifications verlangt: macht neuere
        // Java-Zeit-APIs auch auf älteren Android-Versionen verfügbar.
        // Ohne diese Zeile bricht der Bau mit „requires core library
        // desugaring" ab.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Der Paketname ist die Identität der Installation: Ein anderer
        // hieße für jedes Gerät neue App, kein Termin, kein Tagebuch.
        applicationId = "de.susasek.sprungkalender"
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
        if (hatEigenenSchluessel) {
            create("release") {
                storeFile = rootProject.file(keystoreDatei!!)
                storePassword =
                    signaturWert("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signaturWert("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword =
                    signaturWert("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Mit eigenem Schlüssel signieren, wenn einer da ist; sonst mit
            // dem Debug-Schlüssel, damit der Bau überall durchläuft. Ein mit
            // dem Debug-Schlüssel signiertes APK lässt sich installieren,
            // aber kein Update darüber legen — den erzeugt jeder Läufer neu.
            signingConfig = if (hatEigenenSchluessel) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // Gehört zu isCoreLibraryDesugaringEnabled oben.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
