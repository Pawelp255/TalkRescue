/**
 * Rate-limit hooks for the translate Edge Function.
 *
 * Phase 1 uses an in-memory sliding window (per isolate). Replace `checkRateLimit`
 * with Redis / Postgres / Upstash in production at scale — the interface stays the same.
 */

export interface RateLimitContext {
  ip: string;
  deviceId?: string;
}

export interface RateLimitResult {
  allowed: boolean;
  retryAfter?: number;
}

export interface RateLimitRule {
  name: string;
  maxRequests: number;
  windowMs: number;
}

/** Default limits from SECURE_TRANSLATION_V1_2.md (tune after TestFlight). */
export const DEFAULT_RATE_LIMIT_RULES: RateLimitRule[] = [
  { name: "ip-minute", maxRequests: 30, windowMs: 60_000 },
  { name: "ip-day", maxRequests: 300, windowMs: 86_400_000 },
  { name: "device-day", maxRequests: 200, windowMs: 86_400_000 },
];

interface CounterEntry {
  count: number;
  windowStart: number;
}

const counters = new Map<string, CounterEntry>();

function counterKey(rule: RateLimitRule, bucket: string): string {
  return `${rule.name}:${bucket}`;
}

function checkRule(
  rule: RateLimitRule,
  bucket: string,
  now: number,
): RateLimitResult {
  const key = counterKey(rule, bucket);
  const entry = counters.get(key);

  if (!entry || now - entry.windowStart >= rule.windowMs) {
    counters.set(key, { count: 1, windowStart: now });
    return { allowed: true };
  }

  if (entry.count >= rule.maxRequests) {
    const retryAfter = Math.ceil(
      (entry.windowStart + rule.windowMs - now) / 1000,
    );
    return { allowed: false, retryAfter: Math.max(retryAfter, 1) };
  }

  entry.count += 1;
  return { allowed: true };
}

/**
 * Check all configured rate-limit rules for this request.
 * Returns the first violation, or allowed if all pass.
 */
export function checkRateLimit(
  ctx: RateLimitContext,
  rules: RateLimitRule[] = DEFAULT_RATE_LIMIT_RULES,
): RateLimitResult {
  const now = Date.now();
  const buckets: string[] = [`ip:${ctx.ip}`];

  if (ctx.deviceId) {
    buckets.push(`device:${ctx.deviceId}`);
  }

  for (const rule of rules) {
    for (const bucket of buckets) {
      // Device-day rule only applies to device buckets.
      if (rule.name === "device-day" && !bucket.startsWith("device:")) {
        continue;
      }
      // IP rules skip device buckets.
      if (rule.name.startsWith("ip-") && !bucket.startsWith("ip:")) {
        continue;
      }

      const result = checkRule(rule, bucket, now);
      if (!result.allowed) {
        return result;
      }
    }
  }

  return { allowed: true };
}

/** Extract client IP from Supabase / proxy headers. */
export function clientIp(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) {
    return forwarded.split(",")[0]?.trim() || "unknown";
  }
  return req.headers.get("x-real-ip")?.trim() || "unknown";
}

/** Optional per-device bucket from iOS Keychain UUID (Phase 2). */
export function deviceIdFromRequest(req: Request): string | undefined {
  const value = req.headers.get("x-device-id")?.trim();
  if (!value || value.length > 128) return undefined;
  return value;
}
