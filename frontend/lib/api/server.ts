import { cookies } from "next/headers";

import { API_V1_PREFIX, getApiUrl } from "./config";
import { ApiClientError, type ApiErrorResponse, type ApiSuccess } from "./types";

const parseResponse = async <T>(response: Response): Promise<T> => {
  if (response.ok) {
    const payload = (await response.json()) as ApiSuccess<T>;
    return payload.data;
  }

  const errorPayload = (await response.json().catch(() => null)) as ApiErrorResponse | null;
  throw new ApiClientError({
    status: response.status,
    code: errorPayload?.error?.code ?? "INTERNAL_ERROR",
    message: errorPayload?.error?.message ?? "Не удалось выполнить запрос к API.",
    details: errorPayload?.error?.details,
    requestId: errorPayload?.requestId ?? null,
  });
};

const buildCookieHeader = async (): Promise<string> => {
  const cookieStore = await cookies();
  return cookieStore
    .getAll()
    .map((cookie) => `${cookie.name}=${cookie.value}`)
    .join("; ");
};

export async function apiServerGet<T>(path: string, init?: RequestInit): Promise<T> {
  const cookieHeader = await buildCookieHeader();
  const response = await fetch(getApiUrl(`${API_V1_PREFIX}${path}`), {
    ...init,
    method: "GET",
    cache: "no-store",
    headers: {
      ...(init?.headers ?? {}),
      cookie: cookieHeader,
    },
  });

  return parseResponse<T>(response);
}

export async function apiServerRequest<T>(path: string, init: RequestInit): Promise<T> {
  const cookieHeader = await buildCookieHeader();
  const response = await fetch(getApiUrl(`${API_V1_PREFIX}${path}`), {
    ...init,
    cache: "no-store",
    headers: {
      "content-type": "application/json",
      ...(init.headers ?? {}),
      cookie: cookieHeader,
    },
  });

  return parseResponse<T>(response);
}
