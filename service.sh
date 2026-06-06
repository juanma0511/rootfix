#!/system/bin/sh
# service.sh — runs late_start (after boot mostly up). Re-asserts sensitive props
# in case the framework republished them after our system.prop pass, and re-deletes
# the custom-ROM markers if anything re-added them.
MODDIR=${0%/*}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done

# Re-assert the high-signal verified-boot / security props (-n = no trigger).
resetprop -n ro.boot.verifiedbootstate green
resetprop -n ro.boot.flash.locked 1
resetprop -n ro.boot.vbmeta.device_state locked
resetprop -n ro.boot.veritymode enforcing
resetprop -n ro.debuggable 0
resetprop -n ro.secure 1
resetprop -n ro.build.type user
resetprop -n ro.build.tags release-keys
resetprop -n ro.boot.warranty_bit 0
resetprop -n ro.warranty_bit 0

# Verified-boot reporting gaps + vendor mirrors (bootloader / customrom cards).
resetprop -n ro.oem_unlock_supported 0
resetprop -n sys.oem_unlock_allowed 0
resetprop -n vendor.boot.verifiedbootstate green
resetprop -n vendor.boot.vbmeta.device_state locked
resetprop -n ro.vendor.boot.warranty_bit 0
resetprop -n vendor.boot.warranty_bit 0
resetprop -n ro.vendor.warranty_bit 0

# Re-delete custom-ROM markers.
for p in ro.modversion ro.cm.version ro.lineage.version ro.crdroid.version \
         ro.pixelexperience.version ro.evolution.version ro.havoc.version \
         ro.pa.version ro.aospa.version ro.resurrection.version ro.magisk.hide; do
  resetprop --delete "$p" 2>/dev/null
done

# --- customrom: scrub ROM keywords from the Build identity fields ---
# Duck Detector's buildFieldScan keyword-matches Build.DISPLAY / Build.HOST
# (ro.build.display.id / ro.build.host) against names like "lineage", "crdroid",
# etc. We only rewrite a prop when it actually leaks one, so stock devices stay
# untouched. Build.FINGERPRINT is intentionally left to Play Integrity Fix,
# which spoofs a complete, self-consistent stock fingerprint.
ROM_KEYWORDS="lineage crdroid aospa paranoid pixelexperience evolution omnirom protonaosp havoc resurrection"
prop_has_marker() {
  _low=$(getprop "$1" 2>/dev/null | tr 'A-Z' 'a-z')
  [ -z "$_low" ] && return 1
  for _kw in $ROM_KEYWORDS; do
    case "$_low" in *"$_kw"*) return 0 ;; esac
  done
  return 1
}

if prop_has_marker ro.build.host; then
  resetprop -n ro.build.host android-build
fi
if prop_has_marker ro.build.display.id; then
  # Keep display.id aligned with the (PIF-)spoofed build id when available.
  _bid=$(getprop ro.build.id 2>/dev/null)
  [ -n "$_bid" ] && resetprop -n ro.build.display.id "$_bid"
fi

# --- build-profile: neutralize eng/userdebug flavor ---
# SystemPropertiesCatalog flags ro.build.flavor when it contains eng/userdebug.
# Rebuild it as <product.name>-user instead of guessing, and only when it is
# actually a dev flavor so stock user builds are untouched.
case "$(getprop ro.build.flavor 2>/dev/null)" in
  *userdebug*|*eng*|*-eng)
    _name=$(getprop ro.product.name 2>/dev/null)
    [ -n "$_name" ] && resetprop -n ro.build.flavor "${_name}-user"
    ;;
esac
