import { systemPromptFor, type ProfileId } from "./prompts.ts";

const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4o-mini";
const MAX_TOKENS = 64;
const TEMPERATURE = 0;
const UPSTREAM_TIMEOUT_MS = 12_000;

interface ChatCompletionResponse {
  choices?: Array<{
    message?: { content?: string };
  }>;
  error?: { message?: string };
}

export function sanitizeOneLine(raw: string): string {
  let text = raw.trim();
  if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
    text = text.slice(1, -1);
  }
  const firstLine = text.split(/\r?\n/)[0];
  return (firstLine ?? "").trim();
}

export async function translateWithOpenAI(
  text: string,
  profileId: ProfileId,
): Promise<{ translation: string } | { error: string; timedOut: boolean }> {
  const apiKey = Deno.env.get("OPENAI_API_KEY")?.trim();
  if (!apiKey) {
    return { error: "OpenAI API key is not configured.", timedOut: false };
  }

  const body = {
    model: MODEL,
    messages: [
      { role: "system", content: systemPromptFor(profileId) },
      { role: "user", content: text },
    ],
    temperature: TEMPERATURE,
    max_tokens: MAX_TOKENS,
  };

  try {
    const response = await fetch(OPENAI_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    });

    const data = (await response.json()) as ChatCompletionResponse;

    if (!response.ok) {
      const message = data.error?.message ??
        `OpenAI request failed (HTTP ${response.status}).`;
      return { error: message, timedOut: false };
    }

    const raw = data.choices?.[0]?.message?.content ?? "";
    const translation = sanitizeOneLine(raw);

    if (!translation) {
      return { error: "OpenAI returned an empty translation.", timedOut: false };
    }

    return { translation };
  } catch (error) {
    const timedOut = error instanceof DOMException &&
      error.name === "TimeoutError";
    if (timedOut) {
      return { error: "OpenAI request timed out.", timedOut: true };
    }
    return {
      error: error instanceof Error ? error.message : "OpenAI request failed.",
      timedOut: false,
    };
  }
}
