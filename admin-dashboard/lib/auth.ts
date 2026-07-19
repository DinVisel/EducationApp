import type { AuthResponse } from "./types";

/// Client-side token storage + login, mirroring the Flutter client's approach
/// (JWT + rotating refresh token). Tokens live in localStorage; the dashboard
/// attaches the access token as a Bearer header on every API call.

const ACCESS_KEY = "tt_admin_access";
const REFRESH_KEY = "tt_admin_refresh";

export const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/$/, "") ??
  "http://localhost:5001";

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(REFRESH_KEY);
}

export function storeTokens(access: string, refresh: string) {
  window.localStorage.setItem(ACCESS_KEY, access);
  window.localStorage.setItem(REFRESH_KEY, refresh);
}

export function clearTokens() {
  window.localStorage.removeItem(ACCESS_KEY);
  window.localStorage.removeItem(REFRESH_KEY);
}

export function isAuthenticated(): boolean {
  return getAccessToken() !== null;
}

/// Signs in with the server admin secret (Admin:AccessSecret). The backend
/// verifies it and returns an Admin JWT — no email/password. Access is granted
/// by holding the secret alone.
export async function login(secret: string): Promise<void> {
  const res = await fetch(`${apiBaseUrl}/api/v1/auth/admin`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ secret }),
  });

  if (res.status === 401) {
    throw new Error("Invalid admin secret.");
  }
  if (!res.ok) {
    throw new Error(`Login failed (${res.status}).`);
  }

  const data = (await res.json()) as AuthResponse;
  storeTokens(data.token, data.refreshToken);
}
