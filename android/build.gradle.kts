allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    if (name == "isar_flutter_libs") {
        project.afterEvaluate {
            val androidExtension = project.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            if (androidExtension != null) {
                if (androidExtension.namespace == null) {
                    androidExtension.namespace = "dev.isar.isar_flutter_libs"
                }
                androidExtension.compileSdk = 34
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
