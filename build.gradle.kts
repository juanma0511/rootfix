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
    "keystore.properties", "keystore.properties.example", "*.keystore", "*.jks",
    "scripts/**",
    "*.zip",
)

val unsignedZipName = "$moduleId-$moduleVersion.zip"
val signedZipName = "$moduleId-$moduleVersion-signed.zip"

tasks.register<Zip>("zipModule") {
    group = "build"
    description = "Packages the Magisk module into build/$unsignedZipName"
    archiveFileName.set(unsignedZipName)
    destinationDirectory.set(layout.buildDirectory)
    from(projectDir) { exclude(nonModuleFiles) }
    doLast {
        println("Built ${destinationDirectory.get().asFile}/${archiveFileName.get()}")
    }
}

// ---------------------------------------------------------------------------
// Signing
//
// Resolution order:
//   1. keystore.properties in the repo root (local builds; gitignored)
//   2. SIGNING_* environment variables (CI / GitHub Actions secrets)
//
// keystore.properties keys: storeFile, storePassword, keyAlias, keyPassword
// env vars:               SIGNING_KEYSTORE_FILE, SIGNING_STORE_PASSWORD,
//                         SIGNING_KEY_ALIAS, SIGNING_KEY_PASSWORD
// Passwords are passed to jarsigner via :env so they never appear in argv.
// ---------------------------------------------------------------------------
data class SigningConfig(
    val storeFile: String,
    val storePassword: String,
    val keyAlias: String,
    val keyPassword: String,
)

fun resolveSigningConfig(): SigningConfig? {
    val ksProps = file("keystore.properties")
    if (ksProps.exists()) {
        val p = Properties().apply { ksProps.reader(Charsets.UTF_8).use { load(it) } }
        val storePassword = p.getProperty("storePassword")
            ?: error("keystore.properties is missing storePassword")
        return SigningConfig(
            storeFile = p.getProperty("storeFile") ?: error("keystore.properties is missing storeFile"),
            storePassword = storePassword,
            keyAlias = p.getProperty("keyAlias") ?: error("keystore.properties is missing keyAlias"),
            keyPassword = p.getProperty("keyPassword") ?: storePassword,
        )
    }
    val env = System.getenv()
    val storeFile = env["SIGNING_KEYSTORE_FILE"]
    val storePassword = env["SIGNING_STORE_PASSWORD"]
    val keyAlias = env["SIGNING_KEY_ALIAS"]
    if (storeFile != null && storePassword != null && keyAlias != null) {
        return SigningConfig(
            storeFile = storeFile,
            storePassword = storePassword,
            keyAlias = keyAlias,
            keyPassword = env["SIGNING_KEY_PASSWORD"] ?: storePassword,
        )
    }
    return null
}

fun jdkTool(name: String): String {
    val javaHome = System.getenv("JAVA_HOME")
    if (!javaHome.isNullOrBlank()) {
        val exe = if (System.getProperty("os.name").startsWith("Windows")) "$name.exe" else name
        val candidate = file("$javaHome/bin/$exe")
        if (candidate.exists()) return candidate.absolutePath
    }
    return name
}

tasks.register<Exec>("signZip") {
    group = "build"
    description = "Signs build/$unsignedZipName into build/$signedZipName with jarsigner"
    dependsOn("zipModule")

    val unsigned = layout.buildDirectory.file(unsignedZipName)
    val signed = layout.buildDirectory.file(signedZipName)
    inputs.file(unsigned)
    outputs.file(signed)

    doFirst {
        val cfg = resolveSigningConfig() ?: error(
            "No signing config found. Create keystore.properties (see " +
                "keystore.properties.example) or set the SIGNING_* env vars. See README.",
        )
        environment("RF_STORE_PASSWORD", cfg.storePassword)
        environment("RF_KEY_PASSWORD", cfg.keyPassword)
        commandLine(
            jdkTool("jarsigner"),
            "-keystore", cfg.storeFile,
            "-storepass:env", "RF_STORE_PASSWORD",
            "-keypass:env", "RF_KEY_PASSWORD",
            "-signedjar", signed.get().asFile.absolutePath,
            "-digestalg", "SHA-256",
            "-sigalg", "SHA256withRSA",
            unsigned.get().asFile.absolutePath,
            cfg.keyAlias,
        )
    }
    doLast { println("Signed ${signed.get().asFile}") }
}

tasks.register<Exec>("verifyZip") {
    group = "verification"
    description = "Verifies the signature on build/$signedZipName"
    val signed = layout.buildDirectory.file(signedZipName)
    inputs.file(signed)
    commandLine(jdkTool("jarsigner"), "-verify", "-verbose", "-certs", signed.get().asFile.absolutePath)
}

tasks.register("clean") {
    group = "build"
    doLast { delete(layout.buildDirectory) }
}

defaultTasks("zipModule")
