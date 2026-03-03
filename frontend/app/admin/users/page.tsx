import Link from "next/link";
import { redirect } from "next/navigation";

import { requireAdminUser } from "@/lib/auth-guards";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { UsersClient } from "./users-client";
import styles from "../admin.module.css";

export const dynamic = "force-dynamic";

type UsersPageProps = {
  searchParams: Promise<{
    q?: string;
    role?: string;
    ban?: string;
  }>;
};

type UserItem = {
  id: string;
  name: string;
  avatarLink: string | null;
  email: string;
  role: "USER" | "ADMIN";
  isBanned: boolean;
  banReason: string | null;
  subscriptionsCount: number;
};

export default async function UsersPage({ searchParams }: UsersPageProps) {
  await requireAdminUser();

  const params = await searchParams;
  const q = (params.q ?? "").trim();
  const role = (params.role ?? "").trim();
  const ban = (params.ban ?? "").trim();

  const query = new URLSearchParams();
  if (q) query.set("q", q);
  if (role) query.set("role", role);
  if (ban) query.set("ban", ban);

  let users: UserItem[] = [];
  try {
    users = await apiServerGet<UserItem[]>(`/admin/users?${query.toString()}`);
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }
    throw error;
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <header className={styles.header}>
          <Link href="/admin" className={styles.backLink}>
            {"<- Back to admin panel"}
          </Link>
          <h1 className={styles.title}>Users</h1>
        </header>

        <form action="/admin/users" method="GET" className={styles.filtersPanel}>
          <input className={styles.input} type="text" name="q" defaultValue={q} placeholder="Search by name or email" />

          <div className={styles.filtersRow}>
            <select className={styles.input} name="role" defaultValue={role === "USER" || role === "ADMIN" ? role : ""}>
              <option value="">All roles</option>
              <option value="USER">User</option>
              <option value="ADMIN">Admin</option>
            </select>

            <select className={styles.input} name="ban" defaultValue={ban === "banned" || ban === "active" ? ban : ""}>
              <option value="">Any ban status</option>
              <option value="active">Active</option>
              <option value="banned">Banned</option>
            </select>
          </div>

          <div className={styles.filterActions}>
            <button type="submit" className={styles.publishButton}>
              Apply
            </button>
            <Link href="/admin/users" className={styles.editLink}>
              Reset
            </Link>
          </div>
        </form>

        <UsersClient users={users} />
      </div>
    </main>
  );
}
