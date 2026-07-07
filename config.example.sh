# Copy this file to `config.sh` and fill in your own values.
# `config.sh` is gitignored — your keys and email never get committed.

# --- API keys ---
# Deepgram (speech-to-text): https://console.deepgram.com  (free credit, URL-input transcription)
export DEEPGRAM_KEY="your_deepgram_api_key"
# Resend (email delivery): https://resend.com  (free tier)
export RESEND_KEY="your_resend_api_key"

# --- Email ---
# Where digests are sent.
RECIPIENT_EMAIL="you@example.com"
# Sender. Resend's onboarding@resend.dev only delivers to your own account email;
# to send elsewhere, verify a domain in Resend and use e.g. digest@yourdomain.com
FROM_EMAIL="onboarding@resend.dev"

# --- Output ---
# Also save each digest as an .html file here. Leave empty ("") to skip saving.
OUTPUT_DIR="$HOME/podcast-digests"

# --- Optional custom analysis layer ---
# Path to a text file whose instructions get appended to the digest prompt,
# but ONLY for channels flagged `custom` in channels.tsv.
# Use this to add your own section (e.g. a domain-specific analysis) without
# putting it in the public repo. Leave empty ("") to disable.
CUSTOM_LAYER_FILE=""

# --- Channels ---
# TSV: Name <TAB> xiaoyuzhou_podcast_id <TAB> flag
#   flag = plain  -> standard digest (A/B/C/D)
#   flag = custom -> also append CUSTOM_LAYER_FILE (if set)
# Find the podcast id in the URL: xiaoyuzhoufm.com/podcast/<id>
CHANNELS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/channels.tsv"

# State file (tracks last-seen episode per channel; gitignored).
STATE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.state.json"
