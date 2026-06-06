export type ErrorCode =
  | "unauthorized"
  | "method_not_allowed"
  | "invalid_body"
  | "rate_limited"
  | "upstream_error"
  | "upstream_timeout"
  | "internal_error";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-device-id",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(
  body: Record<string, unknown>,
  status: number,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function errorResponse(
  code: ErrorCode,
  message: string,
  status: number,
  extra: Record<string, unknown> = {},
): Response {
  return jsonResponse({ error: code, message, ...extra }, status);
}

export function corsPreflightResponse(): Response {
  return new Response(null, { status: 204, headers: corsHeaders });
}
