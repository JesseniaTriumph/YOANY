#!/bin/zsh
set -euo pipefail

ROOT_DIR="${1:-.}"

forbidden_patterns=(
  "\\bFirebase\\b"
  "\\bSupabase\\b"
  "\\bSentry\\b"
  "\\bBugsnag\\b"
  "\\bCrashlytics\\b"
  "\\bMixpanel\\b"
  "\\bAmplitude\\b"
  "\\bFullStory\\b"
  "\\bGoogleAnalytics\\b"
  "\\bCloudKit\\b"
  "\\bOpenAI\\b"
  "\\bAnthropic\\b"
  "\\bGemini\\b"
  "\\bDeepL\\b"
  "OPENAI_API_KEY"
  "ANTHROPIC_API_KEY"
  "GEMINI_API_KEY"
  "SUPABASE_(ANON|SERVICE_ROLE)_KEY"
  "SENTRY_DSN"
  "MIXPANEL_TOKEN"
  "AMPLITUDE_API_KEY"
  "API_KEY\\s*="
  "SECRET\\s*="
  "TOKEN\\s*="
  "https://"
  "http://"
)

scan_exit_code=0

for pattern in "${forbidden_patterns[@]}"; do
  if rg -n \
    -P \
    --glob 'Package.swift' \
    --glob 'Sources/**' \
    --glob '.github/**' \
    --glob '*.plist' \
    --glob '*.entitlements' \
    --glob '*.xcconfig' \
    --glob '*.pbxproj' \
    --glob '!**/xcuserdata/**' \
    --glob '!**/.build/**' \
    "$pattern" "$ROOT_DIR" >/dev/null; then
    echo "Forbidden capability marker detected: $pattern"
    scan_exit_code=1
  fi
done

forbidden_entitlement_patterns=(
  "com\\.apple\\.developer\\.icloud"
  "com\\.apple\\.security\\.application-groups"
  "com\\.apple\\.developer\\.associated-domains"
  "aps-environment"
)

entitlement_files=()
while IFS= read -r path; do
  entitlement_files+=("$path")
done < <(find "$ROOT_DIR" -path '*/xcuserdata/*' -prune -o -name '*.entitlements' -print)

for entitlement_path in "${entitlement_files[@]}"; do
  echo "Entitlements file detected: $entitlement_path"
  scan_exit_code=1

  for pattern in "${forbidden_entitlement_patterns[@]}"; do
    if rg -n -P "$pattern" "$entitlement_path" >/dev/null; then
      echo "Forbidden entitlement detected in $entitlement_path: $pattern"
      scan_exit_code=1
    fi
  done
done

exit "$scan_exit_code"
