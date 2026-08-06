import com.android.build.gradle.BaseExtension

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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    plugins.whenPluginAdded {
        if (this.javaClass.name.contains("com.android.build.gradle.LibraryPlugin") ||
            this.javaClass.name.contains("com.android.build.gradle.AppPlugin")) {
            configure<BaseExtension> {
                if (namespace == null) {
                    namespace = project.group.toString()
                }
            }
        }
    }
}
