# Root Fix

A Magisk / KernelSU / APatch module that rewrites the system properties common
root-detection apps read, so the **bootloader**, **custom-ROM**, **SELinux** and
**build-profile** checks report stock-device values.

It is a **property layer only**. It does *not* hide `su`, mounts, Zygisk, the
native-root sockets, or fake TEE/Play-Integrity attestation. Pair it with:

- **Magisk DenyList** (or KernelSU/APatch equivalent)
- **Shamiko** (mount/Zygisk concealment)
- **Play Integrity Fix** (TEE attestation + a complete, self-consistent
  `ro.build.fingerprint`)

## What it changes

| Area | Props |
| --- | --- |
| Security core | `ro.secure`, `ro.debuggable`, `ro.adb.secure`, `service.adb.root`, `persist.sys.usb.config`, `ro.crypto.state`, `ro.allow.mock.location`, `ro.boot.selinux`, `ro.build.selinux` |
| Verified boot | `ro.boot.verifiedbootstate`, `ro.boot.flash.locked`, `ro.boot.veritymode`, `ro.boot.vbmeta.device_state`, `ro.boot.vbmeta.hash_alg/invalidate_on_error`, `ro.boot.secureboot`, `sys.oem_unlock_allowed`, `ro.oem_unlock_supported`, warranty bits, Knox state, and the `vendor.boot.*` mirrors |
| Partition dm-verity | `partition.{system,vendor,product,system_ext,odm}.verified` |
| Build profile | `ro.build.type`, `ro.build.tags`, and `ro.build.flavor` when it is `eng`/`userdebug` |
| Custom ROM | Deletes `ro.modversion`, `ro.cm.version`, `ro.lineage.version`, … and scrubs ROM names leaked through `Build.DISPLAY`/`Build.HOST` |

These map directly to the `BootloaderCatalog`, `SystemPropertiesCatalog` and
`CustomRomCatalog` rule sets used by Duck Detector.

Property changes are applied at boot via `system.prop`, deleted early in
`post-fs-data.sh`, re-asserted in `service.sh`, and the shared logic lives in
`common.sh`.

## Action button

The module ships an `action.sh`. Tap **Action** next to *Root Fix* in your
manager to re-apply every tweak **live, without a reboot** — handy right before
running a detector if the framework republished a value.

> SELinux must be genuinely **Enforcing**. These props only change what
> `getprop` reports; faking `enforcing` while the kernel is permissive is caught
> by the runtime SELinux probes.

## Build locally

Requires a JDK (e.g. Temurin 17). The Gradle wrapper is included.

```sh
./gradlew zipModule          # -> build/rootfix-<version>.zip (flashable)
```

## Sign it

1. Generate a keystore and the GitHub-secret values in one go:

   ```sh
   bash scripts/make-keystore.sh
   ```

   This writes `rootfix.jks` + a gitignored `keystore.properties`, and prints
   the base64 keystore and passwords to paste into GitHub.

   (Or copy `keystore.properties.example` to `keystore.properties` and fill it
   in by hand for an existing keystore.)

2. Build a signed zip:

   ```sh
   ./gradlew signZip            # -> build/rootfix-<version>-signed.zip
   ./gradlew verifyZip          # confirm the signature
   ```

## Upload the keys to GitHub Secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret**.
Add the four values printed by `make-keystore.sh`:

| Secret | Value |
| --- | --- |
| `SIGNING_KEYSTORE_BASE64` | base64 of your `.jks` |
| `SIGNING_STORE_PASSWORD` | keystore password |
| `SIGNING_KEY_ALIAS` | key alias (`rootfix` by default) |
| `SIGNING_KEY_PASSWORD` | key password |

The `Build module` workflow decodes the keystore and runs `signZip`/`verifyZip`
on every push; pushing a `v*` tag publishes the signed zip as a GitHub Release.
Forked-PR builds (no secret access) fall back to an unsigned zip.

> Keep `rootfix.jks` and `keystore.properties` private — both are gitignored.
