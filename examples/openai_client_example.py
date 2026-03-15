import os

from openai import OpenAI

client = OpenAI(
    base_url=os.environ.get("OPENAI_BASE_URL", "http://127.0.0.1:4000/v1"),
    api_key=os.environ["OPENAI_API_KEY"],
)

# Swap model aliases without changing client code:
# gpt-openai, claude-sonnet-4-6-anthropic, claude-haiku-4-5-anthropic, gemini-3-flash-preview-api,
# gemini-2-5-flash-api, gemini-2-5-flash-lite-api, gemini-robotics-er-1-5-preview-api,
# qwen-local-3.5-9b-256k, qwen-local-3.5-27b-256k
resp = client.chat.completions.create(
    model="gpt-openai",
    messages=[{"role": "user", "content": "Reply with: proxy is working"}],
)

print(resp.choices[0].message.content)
