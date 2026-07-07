#!/usr/bin/env bash
# Fetch + transcribe a single Xiaoyuzhou (小宇宙) episode.
# Usage: ./fetch_transcript.sh <xiaoyuzhou_episode_url> [out_dir]
# Deps: curl, python3. Transcription runs on Deepgram (no local ffmpeg/whisper needed).

set -uo pipefail
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
[ -f "$SELF/config.sh" ] && source "$SELF/config.sh" || { echo "Missing config.sh (copy config.example.sh)"; exit 2; }

URL="${1:?Usage: fetch_transcript.sh <episode_url> [out_dir]}"
OUT="${2:-/tmp/podcast-digest}"; mkdir -p "$OUT"
UA="Mozilla/5.0 (Macintosh)"

HTML=$(curl -sL --max-time 30 -A "$UA" "$URL")
TITLE=$(printf '%s' "$HTML" | grep -oE '<meta property="og:title" content="[^"]*"' | head -1 | sed -E 's/.*content="([^"]*)".*/\1/')
AUDIO=$(printf '%s' "$HTML" | grep -oE 'https?://[^"'"'"' ]+\.m4a[^"'"'"' ]*' | head -1)
[ -n "$AUDIO" ] || { echo "No .m4a audio URL found (page layout may have changed)"; exit 1; }
echo "Title: ${TITLE:-<none>}"
echo "Audio: $AUDIO"

echo "Transcribing via Deepgram..." >&2
curl -s --max-time 1800 -X POST \
  'https://api.deepgram.com/v1/listen?model=nova-2&language=zh&diarize=true&punctuate=true&utterances=true' \
  -H "Authorization: Token $DEEPGRAM_KEY" -H 'Content-Type: application/json' \
  -d "{\"url\":\"$AUDIO\"}" > "$OUT/raw.json"

python3 - "$OUT/raw.json" "$OUT/transcript.txt" <<'PY'
import json,re,sys
try: d=json.load(open(sys.argv[1]))
except Exception: open(sys.argv[2],'w').write(""); sys.exit(0)
utt=d.get("results",{}).get("utterances")
if not utt: open(sys.argv[2],'w').write(""); sys.exit(0)
lines=[]
for u in utt:
    t=re.sub(r'(?<=[一-鿿])\s+(?=[一-鿿])','',u["transcript"])
    lines.append(f"[Speaker{u.get('speaker','?')}] {t}")
open(sys.argv[2],'w',encoding='utf-8').write("\n".join(lines))
PY
echo "OK -> $OUT/transcript.txt ($(wc -l < "$OUT/transcript.txt") segments)"
