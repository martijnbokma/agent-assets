#!/usr/bin/env bash
# Build a JSONL manifest of in-scope source files for finding-refactor-candidates.
# Usage:
#   build-manifest.sh --root cli --extensions "ts,tsx" [--output manifest.jsonl]
set -euo pipefail

ROOT=""
EXTENSIONS=""
OUTPUT=""
EXCLUSION_LOG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --extensions)
      EXTENSIONS="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    --exclusion-log)
      EXCLUSION_LOG="${2:-}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: build-manifest.sh --root <path> --extensions \"ts,tsx\" [--output manifest.jsonl]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ROOT" || -z "$EXTENSIONS" ]]; then
  echo "Required: --root and --extensions" >&2
  exit 1
fi

if [[ ! -d "$ROOT" ]]; then
  echo "Root not found: $ROOT" >&2
  exit 1
fi

if [[ -z "$OUTPUT" ]]; then
  OUTPUT="$(mktemp -t refactor-manifest.XXXXXX.jsonl)"
fi

if [[ -z "$EXCLUSION_LOG" ]]; then
  EXCLUSION_LOG="$(mktemp -t refactor-exclusions.XXXXXX.log)"
fi

IFS=',' read -ra EXT_ARR <<< "$EXTENSIONS"

should_exclude() {
  local path="$1"
  case "$path" in
    node_modules/*|*/node_modules/*)
      return 0
      ;;
    dist/*|*/dist/*|build/*|*/build/*|.next/*|*/.next/*|out/*|*/out/*|coverage/*|*/coverage/*)
      return 0
      ;;
    .git/*|*/.git/*|vendor/*|*/vendor/*|__pycache__/*|*/__pycache__/*|.venv/*|*/.venv/*|venv/*|*/venv/*)
      return 0
      ;;
    *.min.js|*.bundle.js)
      return 0
      ;;
    *.generated.ts|*.gen.ts)
      return 0
      ;;
  esac
  return 1
}

exclude_reason() {
  local path="$1"
  case "$path" in
    node_modules/*|*/node_modules/*)
      echo "third-party:node_modules"
      ;;
    dist/*|*/dist/*|build/*|*/build/*|.next/*|*/.next/*|out/*|*/out/*)
      echo "build-output"
      ;;
    coverage/*|*/coverage/*)
      echo "generated-reports"
      ;;
    .git/*|*/.git/*)
      echo "vcs-metadata"
      ;;
    vendor/*|*/vendor/*)
      echo "third-party:vendor"
      ;;
    __pycache__/*|*/__pycache__/*|.venv/*|*/.venv/*|venv/*|*/venv/*)
      echo "python-env"
      ;;
    *.min.js|*.bundle.js)
      echo "minified-bundle"
      ;;
    *.generated.ts|*.gen.ts)
      echo "codegen"
      ;;
    *)
      echo "excluded-by-default"
      ;;
  esac
}

# Build find predicates: \( -name '*.ts' -o -name '*.tsx' \)
FIND_EXPR=()
for i in "${!EXT_ARR[@]}"; do
  ext="${EXT_ARR[$i]// /}"
  [[ -z "$ext" ]] && continue
  if [[ $i -eq 0 ]]; then
    FIND_EXPR+=( -name "*.${ext}" )
  else
    FIND_EXPR+=( -o -name "*.${ext}" )
  fi
done

if [[ ${#FIND_EXPR[@]} -eq 0 ]]; then
  echo "No valid extensions in: $EXTENSIONS" >&2
  exit 1
fi

: > "$OUTPUT"
: > "$EXCLUSION_LOG"
count=0
excluded=0

while IFS= read -r -d '' file; do
  if should_exclude "$file"; then
    excluded=$((excluded + 1))
    printf '%s | %s\n' "$file" "$(exclude_reason "$file")" >> "$EXCLUSION_LOG"
    continue
  fi
  lines=$(wc -l < "$file" | tr -d ' ')
  ext="${file##*.}"
  printf '{"path":"%s","lines":%s,"ext":"%s","root":"%s"}\n' \
    "$file" "$lines" "$ext" "$ROOT" >> "$OUTPUT"
  count=$((count + 1))
done < <(find "$ROOT" -type f \( "${FIND_EXPR[@]}" \) -print0 2>/dev/null)

enumeration_count=$((count + excluded))

echo "manifest: $OUTPUT"
echo "exclusion_log: $EXCLUSION_LOG"
echo "included: $count"
echo "excluded_by_default: $excluded"
echo "enumerated_in_scope: $enumeration_count"
echo "SCAN_RECONCILIATION: $count + $excluded = $enumeration_count"
echo "SCAN_COVERAGE: $count/$count (0 pending in manifest for root $ROOT)"
