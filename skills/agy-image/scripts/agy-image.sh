#!/usr/bin/env bash
# agy-image.sh — generate an image via agy (Antigravity CLI) headless.
# Uses agy's AI Pro quota. Prints the absolute path of the generated file.
#
# Usage:
#   agy-image.sh "<prompt>" <output-dir-or-path> [timeout_sec]
#
#   <output-dir-or-path>: a DIRECTORY (trailing slash, or no file extension)
#     → agy names the file, script detects the newest new file.
#     a FILE path (has an extension) → requested as the save name.
#
# Exit codes: 0 ok (prints path); 1 agy failed; 2 no file located.
set -uo pipefail

PROMPT="${1:?usage: agy-image.sh \"<prompt>\" <output-dir-or-path> [timeout_sec]}"
OUT="${2:?missing output dir or path}"
TIMEOUT="${3:-180}"

# Resolve save directory: trailing slash or extension-less basename => dir.
if [[ "$OUT" == */ ]] || [[ "$(basename "$OUT")" != *.* ]]; then
  SAVE_DIR="${OUT%/}"
else
  SAVE_DIR="$(dirname "$OUT")"
fi
mkdir -p "$SAVE_DIR"

# Snapshot existing files so we can detect the newly generated one.
BEFORE="$(ls -A "$SAVE_DIR" 2>/dev/null || true)"

FULL_PROMPT="${PROMPT}. Save the generated image into the directory ${SAVE_DIR}. After saving, print ONLY the absolute file path on the final line."

# CRITICAL arg order: flags FIRST, --print "<prompt>" LAST.
if ! RAW=$(agy --dangerously-skip-permissions --print-timeout="${TIMEOUT}s" --print "$FULL_PROMPT" 2>&1); then
  echo "ERROR: agy exited non-zero" >&2
  printf '%s\n' "$RAW" >&2
  exit 1
fi

# Candidate 1: last output line that is an existing file path.
PATH_OUT=""
while IFS= read -r line; do
  cand="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^`//' -e 's/`$//' -e 's/^"//' -e 's/"$//')"
  [[ -n "$cand" && -f "$cand" ]] && PATH_OUT="$cand"
done <<< "$RAW"

# Candidate 2 (fallback): newest file in SAVE_DIR not present before agy ran.
if [[ -z "$PATH_OUT" ]]; then
  while IFS= read -r f; do
    base="$(basename "$f")"
    if ! grep -qxF "$base" <<<"$BEFORE" 2>/dev/null; then
      PATH_OUT="${SAVE_DIR}/${base}"
      break
    fi
  done < <(ls -t "$SAVE_DIR" 2>/dev/null)
fi

if [[ -z "$PATH_OUT" ]]; then
  echo "ERROR: could not locate the generated file" >&2
  printf '%s\n' "$RAW" >&2
  exit 2
fi

printf '%s\n' "$PATH_OUT"
