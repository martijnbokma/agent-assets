#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_MANIFEST="$SCRIPT_DIR/build-manifest.sh"
COLLECT_SIGNALS="$SCRIPT_DIR/collect-signals.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $message (expected=$expected actual=$actual)" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if ! grep -Fq "$needle" <<< "$haystack"; then
    echo "FAIL: $message (missing: $needle)" >&2
    exit 1
  fi
}

TMP_DIR="$(mktemp -d -t frc-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/src" "$TMP_DIR/dist" "$TMP_DIR/node_modules/pkg"

cat > "$TMP_DIR/src/main.ts" <<'TS'
export function main() {
  // TODO: improve
  throw new Error("not implemented")
}
TS

cat > "$TMP_DIR/src/feature.ts" <<'TS'
export function feature() {
  throw new Error("not implemented")
}
TS

cat > "$TMP_DIR/src/widget.ts" <<'TS'
export function widget() {
  debugger
  console.log("a")
  console.debug("b")
  console.info("c")
  // TODO: follow-up
  return true
}
TS

cat > "$TMP_DIR/src/widget2.ts" <<'TS'
export const widget2 = () => true
TS

cat > "$TMP_DIR/src/widget.test.ts" <<'TS'
export function testOnly() {
  debugger
  console.log("only test")
}
TS

cat > "$TMP_DIR/src/ignore.generated.ts" <<'TS'
export const generated = true
TS

cat > "$TMP_DIR/dist/bundle.ts" <<'TS'
export const bundle = true
TS

cat > "$TMP_DIR/node_modules/pkg/index.ts" <<'TS'
export const external = true
TS

manifest_out="$($BUILD_MANIFEST --root "$TMP_DIR" --extensions "ts")"
manifest_path="$(awk -F': ' '/^manifest:/ {print $2}' <<< "$manifest_out")"
exclusion_log="$(awk -F': ' '/^exclusion_log:/ {print $2}' <<< "$manifest_out")"
included="$(awk -F': ' '/^included:/ {print $2}' <<< "$manifest_out")"
excluded="$(awk -F': ' '/^excluded_by_default:/ {print $2}' <<< "$manifest_out")"
enumerated="$(awk -F': ' '/^enumerated_in_scope:/ {print $2}' <<< "$manifest_out")"

assert_eq "$included" "5" "manifest should include only non-excluded ts files"
assert_eq "$excluded" "3" "manifest should count excluded ts files"
assert_eq "$enumerated" "8" "enumeration should reconcile included + excluded"
assert_eq "$(wc -l < "$manifest_path" | tr -d ' ')" "5" "manifest row count must equal included count"

log_content="$(cat "$exclusion_log")"
assert_contains "$log_content" "dist/bundle.ts | build-output" "dist file should be exclusion-logged"
assert_contains "$log_content" "node_modules/pkg/index.ts | third-party:node_modules" "node_modules file should be exclusion-logged"
assert_contains "$log_content" "src/ignore.generated.ts | codegen" "codegen file should be exclusion-logged"

prod_signal="$($COLLECT_SIGNALS --file "$TMP_DIR/src/widget.ts")"
prod_score="$(sed -E 's/.*"skeleton_score":([0-9]+).*/\1/' <<< "$prod_signal")"
assert_eq "$prod_score" "28" "widget.ts skeleton score should match debugger + console cap + TODO"
assert_contains "$prod_signal" "\"twin-filename\"" "widget.ts should detect widget2.ts as twin filename"

test_signal="$($COLLECT_SIGNALS --file "$TMP_DIR/src/widget.test.ts")"
assert_contains "$test_signal" "\"skipped\":\"test-path\"" "test file should be skipped by default"

included_test_signal="$($COLLECT_SIGNALS --file "$TMP_DIR/src/widget.test.ts" --include-tests)"
included_test_score="$(sed -E 's/.*"skeleton_score":([0-9]+).*/\1/' <<< "$included_test_signal")"
assert_eq "$included_test_score" "15" "test file scoring should be enabled when include-tests is set"

not_impl_signal="$($COLLECT_SIGNALS --file "$TMP_DIR/src/main.ts")"
not_impl_score="$(sed -E 's/.*"skeleton_score":([0-9]+).*/\1/' <<< "$not_impl_signal")"
assert_eq "$not_impl_score" "18" "main.ts score should count not-implemented + TODO"

echo "PASS: finding-refactor-candidates smoke checks"
