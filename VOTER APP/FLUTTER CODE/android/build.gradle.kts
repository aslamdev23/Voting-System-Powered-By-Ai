buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Updated Kotlin Gradle plugin to the latest stable version as of April 2025
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.20")
        // Updated Android Gradle Plugin (AGP) to a compatible version
        classpath("com.android.tools.build:gradle:8.4.0")
        // Updated Google Services plugin to the latest version
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory configuration (kept as is unless you want to change it)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}