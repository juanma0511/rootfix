#!/usr/bin/env bash
# make-keystore.sh — generate a signing keystore for the module and print the
# values to paste into GitHub repo secrets (Settings -> Secrets and variables
# -> Actions). Run from the repo root:  bash scripts/make-keystore.sh
set -euo pipefail

KS_FILE="${KS_FILE:-rootfix.jks}"
KS_ALIAS="${KS_ALIAS:-rootfix}"
VALIDITY_DAYS="${VALIDITY_DAYS:-10000}"

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found. Install a JDK (e.g. Temurin 17) and retry." >&2
  exit 1
fi

if [ -f "$KS_FILE" ]; then
  echo "Refusing to overwrite existing $KS_FILE" >&2
  exit 1
fi

read -r -s -p "Choose a keystore password: " KS_PASS; echo
read -r -s -p "Confirm password: " KS_PASS2; echo
[ "$KS_PASS" = "$KS_PASS2" ] || { echo "Passwords do not match." >&2; exit 1; }

keytool -genkeypair \
  -keystore "$KS_FILE" \
  -alias "$KS_ALIAS" \
  -keyalg RSA -keysize 4096 \
  -validity "$VALIDITY_DAYS" \
  -storepass "$KS_PASS" -keypass "$KS_PASS" \
  -dname "CN=rootfix, OU=rootfix, O=rootfix, C=US"

# Write local signing config (gitignored) so `./gradlew signZip` works now.
cat > keystore.properties <<EOF
storeFile=$KS_FILE
storePassword=$KS_PASS
keyAlias=$KS_ALIAS
keyPassword=$KS_PASS
EOF
echo "Wrote keystore.properties (gitignored). Local signing is ready:"
echo "    ./gradlew signZip"
echo

# base64 helper that works on both Linux and macOS.
b64() { if base64 --help 2>&1 | grep -q -- '-w'; then base64 -w0 "$1"; else base64 "$1" | tr -d '\n'; fi; }

echo "=================================================================="
echo " Add these as GitHub Actions repository secrets:"
echo "=================================================================="
echo "SIGNING_KEYSTORE_BASE64 :"
b64 "$KS_FILE"; echo
echo "------------------------------------------------------------------"
echo "SIGNING_STORE_PASSWORD  : $KS_PASS"
echo "SIGNING_KEY_ALIAS       : $KS_ALIAS"
echo "SIGNING_KEY_PASSWORD    : $KS_PASS"
echo "=================================================================="
echo "Keep $KS_FILE and these values secret. Do NOT commit them."
