allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Add Google services classpath for Firebase
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// Reverted custom build directory relocation. The previous configuration moved
// build outputs to ../../build which triggered Kotlin incremental compiler
// cache path mismatches ("this and base files have different roots"), causing
// Gradle daemon crashes during assembleDebug. Keeping default build directory
// layout restores expected relative path structure for Kotlin/AGP.

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
