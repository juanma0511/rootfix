#!/system/bin/sh
# customize.sh — runs during flashing in the Magisk app / recovery.
SKIPUNZIP=0

ui_print "*********************************"
ui_print " Root Fix — property layer"
ui_print "*********************************"
ui_print "- Spoofs flagged system properties (build/verified-boot/selinux)"
ui_print "- Deletes custom-ROM version markers"
ui_print ""
ui_print "! This module ONLY covers the property/bootloader/customrom checks."
ui_print "! For su / mount / zygisk / native-root checks you ALSO need:"
ui_print "!   - DenyList enabled"
ui_print "!   - Play Integrity Fix (for TEE / attestation)"
ui_print ""

# Keep SELinux genuinely enforcing — faking 'enforcing' while permissive is caught.
if [ "$(getenforce 2>/dev/null)" = "Permissive" ]; then
  ui_print "! WARNING: SELinux is currently Permissive on this device."
  ui_print "!          Set it to Enforcing or the selinux card stays red."
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
ui_print "- Done. Reboot to apply."
