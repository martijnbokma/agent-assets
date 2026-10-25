#!/usr/bin/env bash
# Collect v4.1 skeleton and file-scope duplication hints for one source file.
# Usage: collect-signals.sh --file path/to/module.ts [--include-tests]
set -euo pipefail

FILE=""
INCLUDE_TESTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE="${2:-}"
      shift 2
      ;;
    --include-tests)
      INCLUDE_TESTS=true
      shift 1
      ;;
    -h|--help)
      echo "Usage: collect-signals.sh --file <path> [--include-tests]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "Required: --file pointing to an existing file" >&2
  exit 1
fi

is_test_path() {
  local path="$1"
  case "$path" in
    *.test.*|*.spec.*|*/__mocks__/*)
      return 0
      ;;
  esac
  return 1
}

if [[ "$INCLUDE_TESTS" != true ]] && is_test_path "$FILE"; then
  printf '{"path":"%s","skeleton_score":0,"skeleton_flags":[],"dup_hints":[],"skipped":"test-path"}\n' "$FILE"
  exit 0
fi

dir=$(dirname "$FILE")
base=$(basename "$FILE")
stem="${base%.*}"
ext="${base##*.}"

skeleton_score=0
flags=()
dup_hints=()

count_matches() {
  local pattern="$1"
  local n
  n=$(rg -c --with-filename "$pattern" "$FILE" 2>/dev/null | awk -F: '{ if (NF == 1) { s += $1 } else { s += $NF } } END {print s+0}') || true
  echo "${n:-0}"
}

not_impl_n=$(count_matches "throw new Error\\(['\\\"]not implemented|NotImplementedError")
if [[ "$not_impl_n" -gt 0 ]]; then
  skeleton_score=$((skeleton_score + (not_impl_n * 15)))
  flags+=("not-implemented")
fi

if [[ $(count_matches "\\bdebugger\\b") -gt 0 ]]; then
  skeleton_score=$((skeleton_score + 10))
  flags+=("debugger")
fi

console_n=$(count_matches "console\\.(log|debug|info)\\(")
if [[ "$console_n" -gt 0 ]]; then
  add=$((console_n * 5))
  [[ $add -gt 15 ]] && add=15
  skeleton_score=$((skeleton_score + add))
  flags+=("console-debug")
fi

todo_n=$(count_matches "TODO|FIXME")
if [[ "$todo_n" -gt 0 ]]; then
  add=$((todo_n * 3))
  skeleton_score=$((skeleton_score + add))
  [[ $skeleton_score -gt 100 ]] && skeleton_score=100
  flags+=("todo-fixme")
fi

for suffix in 2 copy old backup; do
  if [[ -f "$dir/${stem}${suffix}.${ext}" || -f "$dir/${stem}.${suffix}.${ext}" || -f "$dir/${stem}-${suffix}.${ext}" ]]; then
    dup_hints+=("twin-filename")
    break
  fi
done

if [[ $skeleton_score -gt 100 ]]; then
  skeleton_score=100
fi

json_array() {
  local items=("$@")
  local out="["
  local first=1
  local item
  for item in "${items[@]}"; do
    [[ -z "$item" ]] && continue
    [[ $first -eq 0 ]] && out+=","
    out+="\"${item}\""
    first=0
  done
  out+="]"
  printf '%s' "$out"
}

flags_json=$(json_array "${flags[@]:-}")
dup_json=$(json_array "${dup_hints[@]:-}")

printf '{"path":"%s","skeleton_score":%s,"skeleton_flags":%s,"dup_hints":%s}\n' \
  "$FILE" "$skeleton_score" "$flags_json" "$dup_json"
