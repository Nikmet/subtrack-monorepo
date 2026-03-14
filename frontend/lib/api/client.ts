import { API_V1_PREFIX, getApiUrl } from "./config";
import { ApiClientError, type ApiErrorResponse, type ApiSuccess } from "./types";
import { beginTopLoaderRequest, endTopLoaderRequest } from "@/lib/top-loader/store";

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

export async function apiClientRequest<T>(path: string, init: RequestInit): Promise<T> {
  beginTopLoaderRequest();
  try {
    const response = await fetch(getApiUrl(`${API_V1_PREFIX}${path}`), {
      ...init,
      credentials: "include",
      headers: {
        ...(init.body instanceof FormData ? {} : { "content-type": "application/json" }),
        ...(init.headers ?? {}),
      },
    });

    return parseResponse<T>(response);
  } finally {
    endTopLoaderRequest();
  }
}

export async function apiClientGet<T>(path: string): Promise<T> {
  beginTopLoaderRequest();
  try {
    const response = await fetch(getApiUrl(`${API_V1_PREFIX}${path}`), {
      method: "GET",
      credentials: "include",
    });
    return parseResponse<T>(response);
  } finally {
    endTopLoaderRequest();
  }
}
