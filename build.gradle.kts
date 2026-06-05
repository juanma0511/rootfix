import java.util.Properties

// Single source of truth: read id/version straight from module.prop so the
// zip name always matches what Magisk installs.
val moduleProps = Properties().apply {
    file("module.prop").reader(Charsets.UTF_8).use { load(it) }
}
val moduleId: String = moduleProps.getProperty("id")
val moduleVersion: String = moduleProps.getProperty("version")

version = moduleVersion

// Repo tooling that must NOT end up inside the flashable zip.
val nonModuleFiles = listOf(
    ".git/**", ".github/**", ".gradle/**", "build/**",
    "gradle/**", "gradlew", "gradlew.bat",
    "build.gradle.kts", "settings.gradle.kts", "gradle.properties",
    "*.md", "update.json", ".gitignore", "LICENSE",
    "*.zip",
)

tasks.register<Zip>("zipModule") {
    group = "build"
    description = "Packages the Magisk module into build/$moduleId-$moduleVersion.zip"
    archiveFileName.set("$moduleId-$moduleVersion.zip")
    destinationDirectory.set(layout.buildDirectory)
    from(projectDir) { exclude(nonModuleFiles) }
    doLast {
        println("Built ${destinationDirectory.get().asFile}/${archiveFileName.get()}")
    }
}

tasks.register("clean") {
    group = "build"
    doLast { delete(layout.buildDirectory) }
}

defaultTasks("zipModule")
