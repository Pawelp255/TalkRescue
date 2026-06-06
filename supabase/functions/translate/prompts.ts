/**
 * Server-owned system prompts for TalkRescue language profiles.
 * Mirrors LanguageProfile.openAISystemPrompt in the iOS app (v1.2).
 * Clients send profileId only — never trust client-supplied prompts.
 */

export const ALLOWED_PROFILE_IDS = ["pl-en", "pl-sv", "pl-es"] as const;

export type ProfileId = (typeof ALLOWED_PROFILE_IDS)[number];

const SYSTEM_PROMPTS: Record<ProfileId, string> = {
  "pl-en":
    "Translate Polish to natural spoken English. Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal or literary. Preserve meaning. No quotes or labels.",
  "pl-sv":
    "Translate Polish to natural spoken Swedish (Sweden). Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal. Preserve meaning. No quotes or labels.",
  "pl-es":
    "Translate Polish to natural spoken Spanish (Spain). Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal. Preserve meaning. No quotes or labels.",
};

export function systemPromptFor(profileId: ProfileId): string {
  return SYSTEM_PROMPTS[profileId];
}

export function isAllowedProfileId(value: string): value is ProfileId {
  return (ALLOWED_PROFILE_IDS as readonly string[]).includes(value);
}
