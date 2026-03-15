# OpenAI + Anthropic Model Pricing Lookup

Last verified: 2026-03-14 (America/Los_Angeles)

All prices are USD per 1M tokens and reflect standard/base text pricing.

## OpenAI Models (from `config/config.yaml`)

| LiteLLM alias | Provider model | Base input ($/1M) | Output ($/1M) |
|---|---|---:|---:|
| `gpt-5-1-openai` | `openai/gpt-5.1` | 1.25 | 10.00 |
| `gpt-5-mini-openai` | `openai/gpt-5-mini` | 0.25 | 2.00 |
| `gpt-5-nano-openai` | `openai/gpt-5-nano` | 0.05 | 0.40 |
| `gpt-4o-mini-openai` | `openai/gpt-4o-mini` | 0.15 | 0.60 |

## Anthropic Models (from `config/config.yaml`)

| LiteLLM alias | Provider model | Base input ($/1M) | Output ($/1M) | Note |
|---|---|---:|---:|---|
| `claude-sonnet-4-6-anthropic` | `anthropic/claude-sonnet-4-6` | 3.00 | 15.00 | Claude Sonnet 4.6 |
| `claude-haiku-4-5-anthropic` | `anthropic/claude-haiku-4-5` | 1.00 | 5.00 | Claude Haiku 4.5 |

## Gemini Models (from `config/config.yaml`)

Pricing units below are USD per 1M tokens (or per 1M characters where explicitly noted by Google).

| LiteLLM alias | Provider model | Text/Image/Video Input | Audio Input | Output | Notes |
|---|---|---:|---:|---:|---|
| `gemini-3-flash-preview-api` | `gemini/gemini-3-flash-preview` | 0.15 | 1.00 | Text: 0.60, Audio: 8.50 | Preview pricing; modality-specific output pricing published by Google |
| `gemini-2-5-flash-api` | `gemini/gemini-2.5-flash` | 0.30 (<=200k), 0.45 (>200k) | 1.00 (<=200k), 1.50 (>200k) | 2.50 (<=200k), 3.50 (>200k) | Tiered by prompt size |
| `gemini-2-5-flash-lite-api` | `gemini/gemini-2.5-flash-lite` | 0.10 (<=200k), 0.15 (>200k) | 0.30 (<=200k), 0.50 (>200k) | 0.40 (<=200k), 0.60 (>200k) | Tiered by prompt size |
| `gemini-robotics-er-1-5-preview-api` | `gemini/gemini-robotics-er-1.5-preview` | Text: 0.50, Image: 3.00 | N/A | Text: 2.00 | Robotics preview model pricing is modality-specific |

## Sources

- OpenAI pricing: https://platform.openai.com/docs/pricing
- Anthropic pricing: https://docs.claude.com/en/docs/about-claude/pricing
- Anthropic model pages:
  - https://www.anthropic.com/claude/sonnet
  - https://www.anthropic.com/claude/haiku
- Gemini pricing: https://ai.google.dev/gemini-api/docs/pricing

## Notes

- Provider pricing changes frequently; re-check official pricing pages before cost-sensitive rollouts.
- This file lists only base input/output rates (not cached input, prompt caching writes/reads, batch, or priority pricing).
