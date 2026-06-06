/**
 * TalkRescue translate Edge Function
 *
 * POST /functions/v1/translate
 * Body: { "text": "...", "profileId": "pl-en" }
 * Response: { "translation": "...", "provider": "openai" }
 *
 * Auth: `apikey` header with TALKRESCUE_API_KEY (verify_jwt = false).
 * This is a separate public app proxy key — NOT the Supabase anon key.
 * It only protects the translation proxy from random calls; OPENAI_API_KEY
 * remains server-only.
 */

import { errorResponse, corsPreflightResponse, jsonResponse } from "./errors.ts";
import { translateWithOpenAI } from "./openai.ts";
import {
  checkRateLimit,
  clientIp,
  deviceIdFromRequest,
} from "./rate-limit.ts";
import { MAX_BODY_BYTES, validateTranslateBody } from "./validation.ts";

function isAuthorized(req: Request): boolean {
  const expected = Deno.env.get("TALKRESCUE_API_KEY")?.trim();
  if (!expected) return false;

  const apikey = req.headers.get("apikey")?.trim();
  if (apikey && apikey === expected) return true;

  // Legacy / mistaken pattern — still accepted for compatibility.
  const auth = req.headers.get("authorization")?.trim();
  if (auth?.toLowerCase().startsWith("bearer ")) {
    const token = auth.slice(7).trim();
    if (token === expected) return true;
  }

  return false;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return errorResponse(
      "method_not_allowed",
      "Only POST is supported.",
      405,
    );
  }

  if (!isAuthorized(req)) {
    return errorResponse(
      "unauthorized",
      "Missing or invalid apikey.",
      401,
    );
  }

  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (contentLength > MAX_BODY_BYTES) {
    return errorResponse(
      "invalid_body",
      `Request body exceeds ${MAX_BODY_BYTES} bytes.`,
      400,
    );
  }

  const rawBody = await req.text();
  if (rawBody.length > MAX_BODY_BYTES) {
    return errorResponse(
      "invalid_body",
      `Request body exceeds ${MAX_BODY_BYTES} bytes.`,
      400,
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawBody);
  } catch {
    return errorResponse("invalid_body", "Body must be valid JSON.", 400);
  }

  const validation = validateTranslateBody(parsed);
  if (!validation.ok) {
    return errorResponse("invalid_body", validation.message, 400);
  }

  const rateLimit = checkRateLimit({
    ip: clientIp(req),
    deviceId: deviceIdFromRequest(req),
  });

  if (!rateLimit.allowed) {
    return errorResponse(
      "rate_limited",
      "Too many translation requests. Try again later.",
      429,
      { retryAfter: rateLimit.retryAfter ?? 60 },
    );
  }

  const { text, profileId } = validation.value;
  const result = await translateWithOpenAI(text, profileId);

  if ("error" in result) {
    if (result.timedOut) {
      return errorResponse("upstream_timeout", result.error, 504);
    }
    return errorResponse("upstream_error", result.error, 502);
  }

  return jsonResponse(
    {
      translation: result.translation,
      provider: "openai",
    },
    200,
  );
});
