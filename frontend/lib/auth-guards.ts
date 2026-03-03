import { redirect } from "next/navigation";

import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

export type AuthorizedUser = {
  id: string;
  email: string;
  name: string;
  role: "USER" | "ADMIN";
  isBanned: boolean;
  banReason: string | null;
  avatarLink?: string | null;
};

export async function getAuthorizedUser(): Promise<AuthorizedUser> {
  try {
    const result = await apiServerGet<{ user: AuthorizedUser }>("/auth/me");
    if (!result.user) {
      redirect("/login");
    }

    if (result.user.isBanned) {
      redirect(`/login?ban=${encodeURIComponent(result.user.banReason ?? "Аккаунт заблокирован.")}`);
    }

    return result.user;
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }

    if (error instanceof ApiClientError && error.code === "BANNED") {
      redirect(`/login?ban=${encodeURIComponent(error.message)}`);
    }

    throw error;
  }
}

export async function requireAdminUser(): Promise<AuthorizedUser> {
  const user = await getAuthorizedUser();
  if (user.role !== "ADMIN") {
    redirect("/");
  }

  return user;
}
