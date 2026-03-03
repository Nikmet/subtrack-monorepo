const serverApiBaseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:4000";

// Browser requests should stay same-origin so auth cookies are scoped to frontend domain.
export const API_BASE_URL = typeof window === "undefined" ? serverApiBaseUrl : "";

export const API_V1_PREFIX = "/api/v1";

export const getApiUrl = (path: string) =>
  `${API_BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;
