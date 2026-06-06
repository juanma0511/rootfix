#!/system/bin/sh
# action.sh — run when you tap the "Action" button next to this module in the
# Magisk / KernelSU / APatch manager. Re-applies every property tweak live, so
# you can re-assert them after the framework republishes a value WITHOUT a
# reboot (e.g. right before running a detector). Magisk runs this with root.
MODDIR=${0%/*}
. "$MODDIR/common.sh"

rf_log "*********************************"
rf_log " Root Fix — applying property layer"
rf_log "*********************************"

rf_log "- Asserting verified-boot / security props..."
rf_assert_props

rf_log "- Deleting custom-ROM / Magisk markers..."
rf_delete_markers

rf_log "- Scrubbing ROM names from Build.* fields..."
rf_scrub_build_fields

# Genuine SELinux state can't be faked safely — warn if it's permissive.
if [ "$(getenforce 2>/dev/null)" = "Permissive" ]; then
  rf_log "! WARNING: SELinux is Permissive. Set it Enforcing or the selinux"
  rf_log "!          card stays red regardless of these props."
fi

rf_log "- Done. Changes are live (no reboot needed)."
rf_log "  Note: su / zygisk / mount / attestation checks still need"
rf_log "  DenyList + Shamiko + Play Integrity Fix."
