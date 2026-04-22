#!/bin/bash
# ABOUTME: Flags MEMORY.md references to branches or files that no longer exist.
# ABOUTME: Runs on SessionStart, emits additionalContext JSON only when stale refs are found.

set -uo pipefail

MEM="$HOME/.claude/projects/-Users-milanrusimov-Documents-Projects-Flutter-serbia-open-data-rpg-claude/memory/MEMORY.md"
PROJECT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

[ -f "$MEM" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

stale=()

while IFS= read -r branch; do
  [ -z "$branch" ] && continue
  if ! git -C "$PROJECT" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    stale+=("branch \`$branch\` no longer exists locally")
  fi
done < <(grep -oE '(feature|fix|hotfix)/[A-Za-z0-9._/-]+' "$MEM" | sort -u)

while IFS= read -r raw; do
  [ -z "$raw" ] && continue
  path="${raw#\`}"
  path="${path%\`}"
  path="${path%%:*}"
  [ -z "$path" ] && continue
  case "$path" in
    /*) [ -e "$path" ] || stale+=("file \`$path\` no longer exists") ;;
    *) [ -e "$PROJECT/$path" ] || stale+=("file \`$path\` no longer exists under \$CLAUDE_PROJECT_DIR") ;;
  esac
done < <(grep -oE '`[A-Za-z0-9._/-]+\.(md|dart|json|yaml|yml|csv)(:[0-9]+(-[0-9]+)?)?`' "$MEM" | sort -u)

[ ${#stale[@]} -eq 0 ] && exit 0

warnings_json=$(printf '%s\n' "${stale[@]}" | jq -R . | jq -s .)
jq -n --argjson w "$warnings_json" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("⚠ MEMORY.md staleness check: the following references no longer match reality. Re-derive from git/filesystem before trusting them.\n\n- " + ($w | join("\n- ")))
  }
}'
