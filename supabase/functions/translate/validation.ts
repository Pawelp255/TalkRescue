import { isAllowedProfileId, type ProfileId } from "./prompts.ts";

/** Max spoken phrase length (chars). Matches SECURE_TRANSLATION_V1_2.md. */
export const MAX_TEXT_LENGTH = 500;

/** Max JSON body size (bytes). */
export const MAX_BODY_BYTES = 1024;

export interface TranslateRequest {
  text: string;
  profileId: ProfileId;
}

export type ValidationResult =
  | { ok: true; value: TranslateRequest }
  | { ok: false; message: string };

export function normalizeText(text: string): string {
  return text.trim().replace(/\s+/g, " ");
}

export function validateTranslateBody(
  raw: unknown,
): ValidationResult {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    return { ok: false, message: "Body must be a JSON object." };
  }

  const body = raw as Record<string, unknown>;

  if (Object.keys(body).length !== 2 || !("text" in body) || !("profileId" in body)) {
    return {
      ok: false,
      message: 'Body must contain only "text" and "profileId".',
    };
  }

  if (typeof body.text !== "string") {
    return { ok: false, message: '"text" must be a string.' };
  }

  if (typeof body.profileId !== "string") {
    return { ok: false, message: '"profileId" must be a string.' };
  }

  const profileId = body.profileId.trim();
  if (!isAllowedProfileId(profileId)) {
    return {
      ok: false,
      message: `Unsupported profileId. Allowed: pl-en, pl-sv, pl-es.`,
    };
  }

  const text = normalizeText(body.text);
  if (text.length === 0) {
    return { ok: false, message: '"text" must not be empty.' };
  }

  if (text.length > MAX_TEXT_LENGTH) {
    return {
      ok: false,
      message: `"text" exceeds maximum length of ${MAX_TEXT_LENGTH} characters.`,
    };
  }

  return { ok: true, value: { text, profileId } };
}
