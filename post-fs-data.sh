#!/system/bin/sh
# post-fs-data.sh — runs early, before the framework starts.
# Used to DELETE properties whose mere presence is flagged (Duck Detector marks
# these with dangerousValues = ["*"], i.e. any value = custom ROM / root).
MODDIR=${0%/*}

# Custom ROM version markers (features/customrom + systemproperties CUSTOM_ROM).
for p in \
  ro.modversion \
  ro.cm.version \
  ro.lineage.version \
  ro.resurrection.version \
  ro.pa.version \
  ro.aospa.version \
  ro.crdroid.version \
  ro.pixelexperience.version \
  ro.evolution.version \
  ro.havoc.version \
  ; do
  resetprop --delete "$p" 2>/dev/null
done

# Magisk runtime markers (systemproperties ROOT_RUNTIME).
resetprop --delete ro.magisk.hide 2>/dev/null
resetprop --delete init.svc.magisk_daemon 2>/dev/null
resetprop --delete init.svc.magisk_service 2>/dev/null
