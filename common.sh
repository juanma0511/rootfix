#!/system/bin/sh
# common.sh — shared runtime logic, sourced by post-fs-data.sh, service.sh and
# action.sh so the boot scripts and the manager's "Action" button apply the
# exact same set of property tweaks. Nothing here reboots; every change is a
# live resetprop that the framework/apps pick up on their next read.

# Custom-ROM version markers + Magisk runtime markers whose mere presence is a
# signal — the safest fix is to delete them entirely.
RF_MARKERS="
ro.modversion
ro.cm.version
ro.lineage.version
ro.resurrection.version
ro.pa.version
ro.aospa.version
ro.crdroid.version
ro.pixelexperience.version
ro.evolution.version
ro.havoc.version
ro.magisk.hide
init.svc.magisk_daemon
init.svc.magisk_service
"

# Custom-ROM name fragments scanned in Build.DISPLAY / Build.HOST.
RF_ROM_KEYWORDS="lineage crdroid aospa paranoid pixelexperience evolution omnirom protonaosp havoc resurrection"

# rf_log MESSAGE — prints via ui_print when defined (action.sh), else to stdout.
rf_log() {
  if command -v ui_print >/dev/null 2>&1; then
    ui_print "$1"
  else
    echo "$1"
  fi
}

# rf_assert_props — set the verified-boot / security / build props to safe
# values, including the vendor.* mirrors the customrom modification scan
# cross-checks. -n = apply without firing property triggers.
rf_assert_props() {
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

  resetprop -n ro.oem_unlock_supported 0
  resetprop -n sys.oem_unlock_allowed 0
  resetprop -n vendor.boot.verifiedbootstate green
  resetprop -n vendor.boot.vbmeta.device_state locked
  resetprop -n ro.vendor.boot.warranty_bit 0
  resetprop -n vendor.boot.warranty_bit 0
  resetprop -n ro.vendor.warranty_bit 0
}

# rf_delete_markers — remove the custom-ROM / Magisk marker props.
rf_delete_markers() {
  for _p in $RF_MARKERS; do
    resetprop --delete "$_p" 2>/dev/null
  done
}

# rf_prop_has_marker PROP — true if PROP's value contains a known ROM name.
rf_prop_has_marker() {
  _low=$(getprop "$1" 2>/dev/null | tr 'A-Z' 'a-z')
  [ -z "$_low" ] && return 1
  for _kw in $RF_ROM_KEYWORDS; do
    case "$_low" in *"$_kw"*) return 0 ;; esac
  done
  return 1
}

# rf_scrub_build_fields — neutralize ROM names leaked through Build.DISPLAY /
# Build.HOST and eng/userdebug flavors. Build.FINGERPRINT is left to PIF.
rf_scrub_build_fields() {
  if rf_prop_has_marker ro.build.host; then
    resetprop -n ro.build.host android-build
  fi
  if rf_prop_has_marker ro.build.display.id; then
    _bid=$(getprop ro.build.id 2>/dev/null)
    [ -n "$_bid" ] && resetprop -n ro.build.display.id "$_bid"
  fi
  case "$(getprop ro.build.flavor 2>/dev/null)" in
    *userdebug*|*eng*|*-eng)
      _name=$(getprop ro.product.name 2>/dev/null)
      [ -n "$_name" ] && resetprop -n ro.build.flavor "${_name}-user"
      ;;
  esac
}

# rf_apply_all — everything, in the order the boot path uses it.
rf_apply_all() {
  rf_assert_props
  rf_delete_markers
  rf_scrub_build_fields
}
