# Copy this file to `config.sh` and fill in your own values.
# `config.sh` is gitignored — your keys and email never get committed.

# --- API keys ---
# Deepgram (speech-to-text): https://console.deepgram.com  (free credit, URL-input transcription)
export DEEPGRAM_KEY="your_deepgram_api_key"
# Resend (email delivery): https://resend.com  (free tier)
export RESEND_KEY="your_resend_api_key"

# --- LLM backend (writes the digest) ---
# Which engine turns the transcript into the digest. Everything else (fetching,
# Deepgram transcription, Resend email) is independent of this choice.
#   claude    = local `claude` CLI (Claude Code); no key needed here
#   codex     = local `codex` CLI; no API key here, but Codex must be logged in
#   anthropic = Anthropic API directly (no CLI)
#   openai    = OpenAI API, or any OpenAI-compatible endpoint (OpenRouter, Together, ...)
#   gemini    = Google Gemini API
#   ollama    = local model via Ollama (offline, free)
export LLM_BACKEND="claude"

# anthropic
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"
# openai (or any OpenAI-compatible endpoint)
export OPENAI_API_KEY=""
export OPENAI_MODEL="gpt-4o"
export OPENAI_BASE_URL="https://api.openai.com/v1"
#   Many providers are OpenAI-compatible — keep LLM_BACKEND="openai", put your key in
#   OPENAI_API_KEY, and switch OPENAI_BASE_URL / OPENAI_MODEL to one of these
#   (verify the exact model name & URL in each provider's docs; they change):
#     Zhipu GLM       BASE="https://open.bigmodel.cn/api/paas/v4"                  MODEL="glm-4.6"
#     DeepSeek        BASE="https://api.deepseek.com"                              MODEL="deepseek-chat"
#     Kimi / Moonshot BASE="https://api.moonshot.cn/v1"                            MODEL="moonshot-v1-8k"
#     Qwen / DashScope BASE="https://dashscope.aliyuncs.com/compatible-mode/v1"    MODEL="qwen-plus"
#     OpenRouter      BASE="https://openrouter.ai/api/v1"                          MODEL="<vendor>/<model>"
#   Tip: China-hosted providers (GLM/DeepSeek/Kimi/Qwen) also avoid the VPN needed
#   for OpenAI/Gemini from within mainland China.
# gemini
export GEMINI_API_KEY=""
export GEMINI_MODEL="gemini-2.0-flash"
# ollama (local, offline, free)
export OLLAMA_HOST="http://localhost:11434"
export OLLAMA_MODEL="qwen2.5:14b"

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
