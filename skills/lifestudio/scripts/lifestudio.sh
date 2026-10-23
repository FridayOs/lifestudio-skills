#!/usr/bin/env bash
# LifeStudio developer API helper for agents.
#
#   lifestudio.sh tools                      # tools this key may call (name, read/write, description)
#   lifestudio.sh schema <tool>              # input schema of one tool
#   lifestudio.sh call <tool> ['<json>']     # call a tool; prints the JSON result
#   lifestudio.sh upload <file>              # upload an image/video (multipart), prints {url,…}
#
# Env:
#   LIFESTUDIO_API_KEY   workspace API key (lsk_…). Never print it.
#   LIFESTUDIO_API_URL   default https://api.lifestud.io/postify/developer
#
# Inside a Paperclip run without LIFESTUDIO_API_KEY in env, the key is read from
# the agent's granted secret `LIFESTUDIO_API_KEY` (or `lifestudio_api_key`).
#
# Exit codes: 0 ok, 1 tool/API error (message on stderr), 2 usage/config error.
set -euo pipefail

API_URL="${LIFESTUDIO_API_URL:-https://api.lifestud.io/postify/developer}"
API_URL="${API_URL%/}"

die() { echo "lifestudio: $1" >&2; exit "${2:-2}"; }
# Message of an error body: {"error":{"message"}} (LifeStudio envelope) or {"message"}.
error_message() { jq -r 'if (.error|type) == "object" then .error.message elif .message then .message else . end | if type == "array" then join("; ") else tostring end' 2>/dev/null <<<"$1" || echo "$1"; }
command -v curl >/dev/null || die "curl is required"
command -v jq >/dev/null || die "jq is required"

load_key() {
  if [[ -n "${LIFESTUDIO_API_KEY:-}" ]]; then return; fi
  if [[ -n "${PAPERCLIP_API_URL:-}" && -n "${PAPERCLIP_API_KEY:-}" ]]; then
    local base="${PAPERCLIP_API_URL%/}"; base="${base%/api}"
    local name
    for name in LIFESTUDIO_API_KEY lifestudio_api_key; do
      LIFESTUDIO_API_KEY="$(curl -sf -X POST -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
        "$base/api/agents/me/secrets/$name/value" 2>/dev/null | jq -r '.value // empty' 2>/dev/null || true)"
      [[ -n "$LIFESTUDIO_API_KEY" ]] && return
    done
  fi
  die "LIFESTUDIO_API_KEY is not set (create a key in LifeStudio → Workspace settings → API keys & MCP and give it to this agent as a secret)"
}

# One MCP JSON-RPC request; prints the `result` object, or fails with the error.
rpc() {
  local method="$1" params="${2:-{\}}"
  local body response status
  body="$(jq -nc --arg method "$method" --argjson params "$params" '{jsonrpc:"2.0", id:1, method:$method, params:$params}')"
  response="$(curl -sS -w '\n%{http_code}' -X POST "$API_URL/mcp" \
    -H "Authorization: Bearer $LIFESTUDIO_API_KEY" \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    --data-binary "$body")" || die "cannot reach $API_URL" 1
  status="${response##*$'\n'}"; response="${response%$'\n'*}"
  if [[ "$status" != 2* ]]; then
    die "HTTP $status: $(error_message "$response")" 1
  fi
  if jq -e '.error' <<<"$response" >/dev/null; then
    die "$(jq -r '.error.message' <<<"$response")" 1
  fi
  jq -c '.result' <<<"$response"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  tools)
    load_key
    rpc tools/list | jq -r '.tools[] | "\(.name)\t\(if .annotations.readOnlyHint then "read" else "write" end)\t\(.description)"'
    ;;
  schema)
    [[ $# -ge 1 ]] || die "usage: lifestudio.sh schema <tool>"
    load_key
    rpc tools/list | jq --arg name "$1" -e '.tools[] | select(.name == $name) | .inputSchema' \
      || die "unknown tool or missing scope: $1" 1
    ;;
  call)
    [[ $# -ge 1 ]] || die "usage: lifestudio.sh call <tool> ['<json arguments>']"
    tool="$1"; args="${2:-{\}}"
    jq -e 'type == "object"' <<<"$args" >/dev/null 2>&1 || die "arguments must be a JSON object"
    load_key
    result="$(rpc tools/call "$(jq -nc --arg name "$tool" --argjson args "$args" '{name:$name, arguments:$args}')")"
    if jq -e '.isError' <<<"$result" >/dev/null; then
      die "$(jq -r '.content[0].text' <<<"$result")" 1
    fi
    jq '.structuredContent // (.content[0].text | fromjson? // .)' <<<"$result"
    ;;
  upload)
    [[ $# -ge 1 && -f "$1" ]] || die "usage: lifestudio.sh upload <file>"
    load_key
    response="$(curl -sS -w '\n%{http_code}' -X POST "$API_URL/v1/media" \
      -H "Authorization: Bearer $LIFESTUDIO_API_KEY" -F "file=@$1")" || die "cannot reach $API_URL" 1
    status="${response##*$'\n'}"; response="${response%$'\n'*}"
    [[ "$status" == 2* ]] || die "HTTP $status: $(error_message "$response")" 1
    jq '.data // .' <<<"$response"
    ;;
  *)
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    [[ -z "$cmd" || "$cmd" == "help" || "$cmd" == "-h" || "$cmd" == "--help" ]] || exit 2
    ;;
esac
