import {
  apiBaseUrl,
  clearTokens,
  getAccessToken,
  getRefreshToken,
  storeTokens,
} from "./auth";
import type { AuthResponse } from "./types";

/// Thrown when the session can't be recovered; callers redirect to /login.
export class UnauthorizedError extends Error {
  constructor() {
    super("Session expired.");
    this.name = "UnauthorizedError";
  }
}

// Single-flight refresh: concurrent 401s share one refresh call (mirrors the
// Flutter dio interceptor in teacher_tracker_app/lib/core/api/api_client.dart).
let refreshPromise: Promise<boolean> | null = null;

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;

  if (!refreshPromise) {
    refreshPromise = (async () => {
      try {
        const res = await fetch(`${apiBaseUrl}/api/v1/auth/refresh`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken }),
        });
        if (!res.ok) return false;
        const data = (await res.json()) as AuthResponse;
        storeTokens(data.token, data.refreshToken);
        return true;
      } catch {
        return false;
      } finally {
        // Cleared on the next tick so all awaiters read the same result first.
        setTimeout(() => (refreshPromise = null), 0);
      }
    })();
  }
  return refreshPromise;
}

async function request<T>(
  path: string,
  init: RequestInit = {},
  retry = true,
): Promise<T> {
  const token = getAccessToken();
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  if (init.body) headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);

  const res = await fetch(`${apiBaseUrl}/api/v1${path}`, { ...init, headers });

  if (res.status === 401 && retry) {
    const refreshed = await refreshAccessToken();
    if (refreshed) return request<T>(path, init, false);
    clearTokens();
    throw new UnauthorizedError();
  }

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(text || `Request failed (${res.status}).`);
  }

  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

export const api = {
  get: <T>(path: string) => request<T>(path, { method: "GET" }),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: "POST",
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
};
