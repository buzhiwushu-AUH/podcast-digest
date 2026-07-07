# AGENTS.md

Guidance for AI coding agents (e.g. Codex) working in this repository.

## What this project is

`podcast-digest` watches Xiaoyuzhou (小宇宙) podcast channels. For each new episode it
transcribes the audio (Deepgram), writes a digest with an LLM backend, and emails it
(Resend). Pure `bash` + `curl` + `python3` (stdlib only). No ffmpeg / Whisper.

Pipeline: episode page → audio URL → Deepgram transcript → LLM digest → Resend email.

## Key files

- `digest.sh` — main entry; watches channels and orchestrates the whole pipeline.
- `fetch_transcript.sh` — transcript only (Deepgram), no LLM and no email.
- `llm_call.py` — API / local-model backends (`anthropic`, `openai`, `gemini`, `ollama`).
- `config.example.sh` — copy to `config.sh` (gitignored) for keys and settings.
- `channels.tsv.example` — copy to `channels.tsv` for the watch list.
- `prompts/digest_prompt.txt` — the digest-writing instructions.

## Helping a user set it up

1. `cp config.example.sh config.sh`, `cp channels.tsv.example channels.tsv`,
   then `chmod +x digest.sh fetch_transcript.sh`.
2. In `config.sh` fill `DEEPGRAM_KEY`, `RESEND_KEY`, `RECIPIENT_EMAIL`, `FROM_EMAIL`,
   and choose `LLM_BACKEND`.
3. Add channels to `channels.tsv` as `Name<TAB>podcast_id<TAB>plain`. The podcast id is
   in the URL `xiaoyuzhoufm.com/podcast/<id>`.
4. Seed first: `./digest.sh --seed` (marks each channel's current latest as seen), then
   run `./digest.sh`.

## Running and testing

- `./digest.sh` — process any channel that has a new episode.
- `./digest.sh --force <podcast_id>` — force the latest of one channel (good for a test run).
- `./fetch_transcript.sh <episode_url>` — transcript only.
- Logs live in `logs/` (`codex.out`, `codex.err`, `llm.err`).

## Using Codex as the LLM backend

If the user has the Codex CLI logged in but no other LLM API key, set `LLM_BACKEND="codex"`.
`digest.sh` then calls `codex exec --skip-git-repo-check --sandbox read-only
--output-last-message <file> -` to write the digest — no extra API key needed, as long as
Codex is logged in on the machine.

Important: `codex` only replaces the digest-writing step. **Deepgram (transcription) and
Resend (email) still require their own keys** — Codex cannot do those two steps.

## Conventions and gotchas

- `config.sh`, `custom_layer.txt`, `.state.json` are gitignored — never commit secrets.
- Two kinds of backends: local CLIs (`claude`, `codex`) are handled directly in `digest.sh`;
  API / local-model backends (`anthropic` / `openai` / `gemini` / `ollama`) go through
  `llm_call.py`.
- `channels.tsv` fields are TAB-separated, not spaces.
- Keep the project dependency-free: `bash` / `curl` / `python3` stdlib only — no pip installs.
