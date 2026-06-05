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

# Re-delete custom-ROM markers.
for p in ro.modversion ro.cm.version ro.lineage.version ro.crdroid.version \
         ro.pixelexperience.version ro.evolution.version ro.havoc.version \
         ro.pa.version ro.aospa.version ro.resurrection.version ro.magisk.hide; do
  resetprop --delete "$p" 2>/dev/null
done
