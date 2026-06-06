#!/system/bin/sh
# post-fs-data.sh — runs early, before the framework starts. Deletes the
# custom-ROM / Magisk marker props whose mere presence is flagged, so they are
# already gone by the time the framework (and any detector) reads them.
MODDIR=${0%/*}
. "$MODDIR/common.sh"

rf_delete_markers
