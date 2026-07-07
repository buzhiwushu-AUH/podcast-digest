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
- **The digest is written by the `claude` CLI** you already have, in headless mode.
- **Scheduling is plain `launchd`/cron.** State is a tiny JSON file, so it only ever
  processes genuinely new episodes.

## Requirements

- macOS or Linux, `bash`, `curl`, `python3` (stdlib only)
- [`claude`](https://docs.claude.com/en/docs/claude-code) CLI (Claude Code), authenticated
- A [Deepgram](https://console.deepgram.com) API key (free credit)
- A [Resend](https://resend.com) API key (free tier)

## Setup

```bash
git clone <your-fork> podcast-digest && cd podcast-digest
cp config.example.sh config.sh          # then edit: keys, recipient email, output dir
cp channels.tsv.example channels.tsv    # then edit: the channels you want to watch
chmod +x digest.sh fetch_transcript.sh
```

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
