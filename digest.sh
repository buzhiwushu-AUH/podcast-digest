#!/usr/bin/env bash
# Watch a list of Xiaoyuzhou (小宇宙) channels; when a channel has a new episode,
# transcribe it (Deepgram), turn it into a digest (LLM backend), email it
# (Resend), optionally save it, and remember it (state file).
#
# Usage:
#   ./digest.sh                 normal: process channels whose latest episode changed
#   ./digest.sh --seed          mark each channel's current latest as seen (no output)
#   ./digest.sh --force <pid>   force-process a channel's latest, ignoring state (test)
#
# Deps: curl, python3, and one configured LLM backend. No ffmpeg/whisper.

set -uo pipefail
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
[ -f "$SELF/config.sh" ] && source "$SELF/config.sh" || { echo "Missing config.sh (copy config.example.sh)"; exit 2; }

UA="Mozilla/5.0 (Macintosh)"
: "${STATE_FILE:="$SELF/.state.json"}"
: "${CHANNELS_FILE:="$SELF/channels.tsv"}"
LOGDIR="$SELF/logs"; mkdir -p "$LOGDIR"
[ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"
MODE="${1:-run}"; FORCE_PID="${2:-}"

log(){ echo "[$(date '+%F %T')] $*"; }
get_state(){ python3 -c "import json;print(json.load(open('$STATE_FILE')).get('$1',''))" 2>/dev/null; }
set_state(){ python3 -c "import json;d=json.load(open('$STATE_FILE'));d['$1']='$2';json.dump(d,open('$STATE_FILE','w'))"; }

# generate_digest <instructions>  —  content on stdin, digest text on stdout.
# `claude` and `codex` use local CLIs; API/local model backends go through llm_call.py.
generate_digest(){
  case "${LLM_BACKEND:-claude}" in
    claude) claude -p "$1" ;;
    codex)
      local out
      out="$(mktemp)"
      {
        printf 'You are the digest-writing step in podcast-digest.\n'
        printf 'Return only the final digest content. Do not explain your process.\n\n'
        printf 'DIGEST INSTRUCTIONS:\n%s\n\n' "$1"
        printf 'EPISODE INPUT:\n'
        cat
      } | codex exec --skip-git-repo-check --sandbox read-only --output-last-message "$out" - >>"$LOGDIR/codex.out" 2>>"$LOGDIR/codex.err"
      local status=$?
      if [ "$status" -ne 0 ]; then
        rm -f "$out"
        return "$status"
      fi
      cat "$out"
      rm -f "$out"
      ;;
    *)      python3 "$SELF/llm_call.py" "$1" ;;
  esac
}

process(){
  local name="$1" pid="$2" flag="$3" force="${4:-}"
  local phtml epid
  phtml=$(curl -sL --max-time 30 -A "$UA" "https://www.xiaoyuzhoufm.com/podcast/$pid")
  epid=$(printf '%s' "$phtml" | grep -oE '/episode/[a-f0-9]{24}' | awk '!s[$0]++' | head -1 | sed 's#/episode/##')
  [ -n "$epid" ] || { log "[$name] no episode id, skip"; return; }

  if [ "$MODE" = "--seed" ]; then set_state "$pid" "$epid"; log "[$name] seeded latest as seen: $epid"; return; fi
  if [ "$force" != "force" ] && [ "$(get_state "$pid")" = "$epid" ]; then log "[$name] no new episode ($epid)"; return; fi

  log "[$name] new episode $epid"
  local W; W=$(mktemp -d)
  local ehtml title audio pub
  ehtml=$(curl -sL --max-time 30 -A "$UA" "https://www.xiaoyuzhoufm.com/episode/$epid")
  title=$(printf '%s' "$ehtml" | grep -oE '<meta property="og:title" content="[^"]*"' | head -1 | sed -E 's/.*content="([^"]*)".*/\1/')
  audio=$(printf '%s' "$ehtml" | grep -oE 'https?://[^"'"'"' ]+\.m4a[^"'"'"' ]*' | head -1)
  pub=$(printf '%s' "$ehtml" | grep -oE '"datePublished":"[^"]*"' | head -1 | sed -E 's/.*:"([^"]*)".*/\1/')
  [ -n "$audio" ] || { log "[$name] no audio, skip"; rm -rf "$W"; return; }

  log "[$name] transcribing (Deepgram)..."
  curl -s --max-time 1800 -X POST \
    'https://api.deepgram.com/v1/listen?model=nova-2&language=zh&diarize=true&punctuate=true&utterances=true' \
    -H "Authorization: Token $DEEPGRAM_KEY" -H 'Content-Type: application/json' -d "{\"url\":\"$audio\"}" > "$W/raw.json"
  python3 - "$W/raw.json" "$W/transcript.txt" <<'PY'
import json,re,sys
try: d=json.load(open(sys.argv[1]))
except Exception: open(sys.argv[2],'w').write(""); sys.exit(0)
utt=d.get("results",{}).get("utterances")
if not utt: open(sys.argv[2],'w').write(""); sys.exit(0)
lines=[f"[Speaker{u.get('speaker','?')}] "+re.sub(r'(?<=[一-鿿])\s+(?=[一-鿿])','',u["transcript"]) for u in utt]
open(sys.argv[2],'w',encoding='utf-8').write("\n".join(lines))
PY
  local tsize; tsize=$(wc -m < "$W/transcript.txt" 2>/dev/null | tr -d ' '); tsize=${tsize:-0}
  [ "$tsize" -gt 100 ] || { log "[$name] transcript empty/short ($tsize), skip"; rm -rf "$W"; return; }
  log "[$name] transcript ${tsize} chars; generating digest (${LLM_BACKEND:-claude})..."

  # Optional custom layer, only for channels flagged 'custom'
  local custom=""
  if [ "$flag" = "custom" ] && [ -n "${CUSTOM_LAYER_FILE:-}" ] && [ -f "$CUSTOM_LAYER_FILE" ]; then
    custom="$(printf '\n\nCUSTOM LAYER:\n%s' "$(cat "$CUSTOM_LAYER_FILE")")"
  fi

  local html
  html=$( { printf 'Title: %s\nPublished: %s\n\n[Machine transcript]\n' "$title" "$pub"; cat "$W/transcript.txt"; } \
    | generate_digest "$(cat "$SELF/prompts/digest_prompt.txt")$custom" 2>>"$LOGDIR/llm.err" )
  html=$(printf '%s' "$html" | sed -E '/^```/d')
  [ -n "$html" ] || { log "[$name] empty digest, skip send"; rm -rf "$W"; return; }

  log "[$name] sending email (Resend)..."
  local rid
  rid=$(TITLE="$title" NAME="$name" HTML="$html" FROM="$FROM_EMAIL" TO="$RECIPIENT_EMAIL" RS="$RESEND_KEY" python3 - <<'PY'
import json,os,subprocess
p=json.dumps({"from":os.environ["FROM"],"to":os.environ["TO"],
 "subject":f'[{os.environ["NAME"]}] {os.environ["TITLE"]}',"html":os.environ["HTML"]})
r=subprocess.run(["curl","-s","-X","POST","https://api.resend.com/emails",
 "-H","Authorization: Bearer "+os.environ["RS"],"-H","Content-Type: application/json","-d",p],
 capture_output=True,text=True)
print(r.stdout)
PY
)
  log "[$name] Resend: $rid"

  if [ -n "${OUTPUT_DIR:-}" ]; then
    mkdir -p "$OUTPUT_DIR"
    local safe; safe=$(printf '%s' "$title" | tr '/:：|' '____' | cut -c1-40)
    { echo "<!-- $name | $pub | $epid | machine transcription -->"; printf '%s' "$html"; } > "$OUTPUT_DIR/${epid}_${safe}.html"
    log "[$name] saved: $OUTPUT_DIR/${epid}_${safe}.html"
  fi

  set_state "$pid" "$epid"
  rm -rf "$W"
}

log "=== run mode=$MODE ==="
while IFS=$'\t' read -r name pid flag; do
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue;; esac
  if [ "$MODE" = "--force" ]; then
    [ "$pid" = "$FORCE_PID" ] && process "$name" "$pid" "${flag:-plain}" "force"
  else
    process "$name" "$pid" "${flag:-plain}"
  fi
done < "$CHANNELS_FILE"
log "=== done ==="
