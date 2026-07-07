---
name: podcast-digest
description: Turn Xiaoyuzhou podcast episodes into email digests using Deepgram, an LLM backend, and Resend. Use when the user wants to set up, run, schedule, or debug podcast digests.
metadata:
  short-description: Generate Xiaoyuzhou podcast digests
---

# Podcast Digest

Use this skill when the user wants to turn Xiaoyuzhou podcast episodes into email digests.

## Setup

1. Copy `config.example.sh` to `config.sh`.
2. Fill in `DEEPGRAM_KEY`, `RESEND_KEY`, `RECIPIENT_EMAIL`, and `FROM_EMAIL`.
3. Copy `channels.tsv.example` to `channels.tsv`.
4. Add podcast channels in this format:

```text
Name<TAB>xiaoyuzhou_podcast_id<TAB>plain
```

For Codex-only users, use the OpenAI backend:

```bash
export LLM_BACKEND="openai"
export OPENAI_API_KEY="..."
export OPENAI_MODEL="gpt-4o"
export OPENAI_BASE_URL="https://api.openai.com/v1"
```

## Commands

Seed current latest episodes:

```bash
./digest.sh --seed
```

Run normally:

```bash
./digest.sh
```

Force one podcast:

```bash
./digest.sh --force <podcast_id>
```

Fetch transcript only:

```bash
./fetch_transcript.sh <episode_url>
```

## Notes

The `claude` backend requires Claude Code CLI. Codex-only users should use `openai`, `ollama`, or another OpenAI-compatible backend.
