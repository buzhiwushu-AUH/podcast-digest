#!/usr/bin/env python3
"""Send (instructions + stdin content) to the configured LLM backend and print the reply.

Backends handled here: anthropic | openai | gemini | ollama.
(The `claude` CLI backend is invoked directly from digest.sh, not here.)

Config comes from environment variables exported by config.sh. Standard library only.
Usage: some_content | llm_call.py "<instructions>"
"""
import os, sys, json, urllib.request, urllib.error


def post(url, headers, payload, timeout=180):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST"
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def main():
    instructions = sys.argv[1] if len(sys.argv) > 1 else ""
    content = sys.stdin.read()
    backend = os.environ.get("LLM_BACKEND", "claude")

    try:
        if backend == "anthropic":
            key = os.environ["ANTHROPIC_API_KEY"]
            model = os.environ.get("ANTHROPIC_MODEL", "claude-sonnet-4-6")
            d = post(
                "https://api.anthropic.com/v1/messages",
                {"x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json"},
                {"model": model, "max_tokens": 4096, "system": instructions,
                 "messages": [{"role": "user", "content": content}]},
            )
            print(d["content"][0]["text"])

        elif backend == "openai":
            key = os.environ["OPENAI_API_KEY"]
            model = os.environ.get("OPENAI_MODEL", "gpt-4o")
            base = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")
            d = post(
                base + "/chat/completions",
                {"Authorization": "Bearer " + key, "Content-Type": "application/json"},
                {"model": model, "messages": [
                    {"role": "system", "content": instructions},
                    {"role": "user", "content": content}]},
            )
            print(d["choices"][0]["message"]["content"])

        elif backend == "gemini":
            key = os.environ["GEMINI_API_KEY"]
            model = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
            d = post(
                url, {"Content-Type": "application/json"},
                {"system_instruction": {"parts": [{"text": instructions}]},
                 "contents": [{"role": "user", "parts": [{"text": content}]}]},
            )
            print(d["candidates"][0]["content"]["parts"][0]["text"])

        elif backend == "ollama":
            host = os.environ.get("OLLAMA_HOST", "http://localhost:11434").rstrip("/")
            model = os.environ.get("OLLAMA_MODEL", "qwen2.5:14b")
            d = post(
                host + "/api/chat", {"Content-Type": "application/json"},
                {"model": model, "stream": False, "messages": [
                    {"role": "system", "content": instructions},
                    {"role": "user", "content": content}]},
            )
            print(d["message"]["content"])

        else:
            sys.stderr.write(f"Unknown LLM_BACKEND: {backend}\n")
            sys.exit(2)

    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:500]
        sys.stderr.write(f"LLM HTTP error ({backend}): {e.code} {body}\n")
        sys.exit(1)
    except urllib.error.URLError as e:
        sys.stderr.write(f"LLM connection error ({backend}): {e}\n")
        sys.exit(1)
    except (KeyError, IndexError) as e:
        sys.stderr.write(f"Unexpected response / missing config ({backend}): {e}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
