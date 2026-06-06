#!/system/bin/sh
# service.sh — runs late_start (after boot mostly up). Re-asserts sensitive props
# in case the framework republished them after our system.prop pass, re-deletes
# the custom-ROM markers, and scrubs ROM names leaked through Build.* fields.
MODDIR=${0%/*}
. "$MODDIR/common.sh"

while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done

rf_apply_all
