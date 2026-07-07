# podcast-digest

Turn **Xiaoyuzhou (小宇宙) podcast episodes into email digests**, automatically.

Point it at some channels; when a new episode drops it gets **transcribed** (Deepgram),
turned into a structured **digest** (concise summary → outline → verbatim quotes →
cleaned transcript) by a headless **Claude** call, and **emailed** to you (Resend).
Runs fully on your machine — **no ffmpeg, no local Whisper**.

Every episode arrives as: **A. Summary · B. Outline · C. Quotes · D. Transcript**.

---

## Why it's lightweight

- **No local speech-to-text.** Deepgram transcribes directly from the episode's audio
  URL, so there's nothing heavy to install.
- **The audio URL is read straight from the episode page** (`og:audio`) — no scraping hacks.
- **The digest is written by whichever LLM you pick** — the `claude` CLI in headless
  mode by default, or any of OpenAI / Anthropic / Gemini / Ollama.
- **Scheduling is plain `launchd`/cron.** State is a tiny JSON file, so it only ever
  processes genuinely new episodes.

## Requirements

Minimum for transcript only:

- macOS or Linux
- `bash`, `curl`, `python3` (stdlib only)
- A [Deepgram](https://console.deepgram.com) API key

For full email digests, also add:

- An **LLM backend** for the digest step — local [`claude`](https://docs.claude.com/en/docs/claude-code)
  CLI, OpenAI / OpenAI-compatible API, Anthropic API, Gemini, or Ollama
- A [Resend](https://resend.com) API key
- Sender and recipient email settings
  
## Setup

```bash
git clone <your-fork> podcast-digest && cd podcast-digest
cp config.example.sh config.sh          # then edit: keys, recipient email, output dir
cp channels.tsv.example channels.tsv    # then edit: the channels you want to watch
chmod +x digest.sh fetch_transcript.sh
```

### Transcript-only quick start

If you only want to transcribe one Xiaoyuzhou episode, you only need `DEEPGRAM_KEY`.

Edit `config.sh`:

```bash
export DEEPGRAM_KEY="your_deepgram_api_key"
```

Then run:

```bash
./fetch_transcript.sh "https://www.xiaoyuzhoufm.com/episode/..."
```

The transcript will be saved to:

```text
/tmp/podcast-digest/transcript.txt
```

### Full email digest setup

For automatic summaries and email delivery, also fill in your LLM backend and Resend settings in `config.sh`.

**Find a channel id:** open the show on xiaoyuzhoufm.com — the URL is
`xiaoyuzhoufm.com/podcast/<id>`. Put that `<id>` in `channels.tsv`
(one per line: `Name <TAB> id <TAB> flag`).

**Seed first**, so it doesn't email you the current back-catalog:

```bash
./digest.sh --seed     # marks each channel's current latest as "already seen"
```

## Usage

```bash
./digest.sh                 # process any channel with a new episode
./digest.sh --force <id>    # force-process a channel's latest (good for a test run)
./fetch_transcript.sh <episode_url>   # just transcribe one episode to a text file
```

## Choose your LLM backend

Only the **digest-writing** step uses an LLM; fetching, transcription (Deepgram) and
email (Resend) are model-agnostic. Pick a backend in `config.sh` via `LLM_BACKEND`:

| `LLM_BACKEND` | What it uses | Notes |
|---|---|---|
| `claude` (default) | local `claude` CLI (Claude Code) | no extra key; reuses your Claude Code auth |
| `anthropic` | Anthropic API directly | set `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL` |
| `openai` | OpenAI **or any OpenAI-compatible** API | set `OPENAI_API_KEY`, `OPENAI_MODEL`, `OPENAI_BASE_URL` (works with OpenRouter, Together, etc.) |
| `gemini` | Google Gemini API | set `GEMINI_API_KEY`, `GEMINI_MODEL` |
| `ollama` | a local model via [Ollama](https://ollama.com) | offline & free; set `OLLAMA_MODEL` |

Everything else stays the same. Non-`claude` backends are called through `llm_call.py`
(standard library only — no pip installs).

**Chinese / other providers work too.** Most are OpenAI-compatible, so just keep
`LLM_BACKEND="openai"` and point `OPENAI_BASE_URL` / `OPENAI_MODEL` at them — presets for
**Zhipu GLM, DeepSeek, Kimi (Moonshot), Qwen (DashScope)** and OpenRouter are listed in
`config.example.sh`. (These are also China-hosted, so no VPN needed from the mainland.)

## Schedule it (daily, macOS)

```bash
cp launchd/com.podcast-digest.plist.example ~/Library/LaunchAgents/com.podcast-digest.plist
# edit the plist: replace __REPO__ and __HOME__ (see comments inside)
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.podcast-digest.plist
```

On Linux, a `cron` entry calling `digest.sh` works just as well.

## Optional: your own analysis layer

Some channels deserve an extra, domain-specific section (a checklist, a scoring rubric,
your own take). Instead of hard-coding that:

1. `cp prompts/custom_layer.example.txt custom_layer.txt` and write your instructions.
2. Set `CUSTOM_LAYER_FILE` in `config.sh` to point at it.
3. Flag those channels as `custom` (instead of `plain`) in `channels.tsv`.

`custom_layer.txt` is gitignored — your private logic never leaves your machine, while the
tool itself stays generic.

## Honest limitations

- **The machine won't run while it's off.** `launchd` catches up on wake if it was asleep,
  but a powered-off machine runs the job at next boot.
- **Machine transcription isn't perfect.** Chinese ASR has homophone errors; the digest
  corrects obvious ones and marks uncertain spots, but the raw transcript is labeled as
  uncorrected. Speaker separation is approximate.
- **US-hosted APIs.** Deepgram/Resend may need a VPN from networks that block them.
- **Small per-episode cost** (Deepgram audio-minutes + your Claude usage).
- Personal-grade automation, not a hardened service.

## Privacy

`config.sh`, `custom_layer.txt`, and `.state.json` are gitignored — keys, your email, and
any private analysis logic never get committed.

## License

MIT — see [LICENSE](LICENSE).
