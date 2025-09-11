buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4") // Version stable
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
        classpath("com.google.gms:google-services:4.3.15")
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuration du répertoire de build
rootProject.layout.buildDirectory.set(File(rootProject.projectDir, "../build").absoluteFile)

subprojects {
    project.layout.buildDirectory.set(File(rootProject.layout.buildDirectory.get().asFile, project.name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}