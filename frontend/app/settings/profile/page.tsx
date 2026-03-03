import Link from "next/link";
import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { SettingsProfileToastTrigger } from "@/app/components/toast/settings-profile-toast-trigger";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { ProfileEditForm } from "./profile-edit-form";
import styles from "./profile.module.css";

export const dynamic = "force-dynamic";

type SettingsProfilePageProps = {
  searchParams: Promise<{
    toast?: string;
  }>;
};

type ProfileUser = {
  name: string;
  email: string;
  avatarLink: string | null;
};

export default async function SettingsProfilePage({ searchParams }: SettingsProfilePageProps) {
  const params = await searchParams;

  let currentUser: ProfileUser | null = null;
  try {
    currentUser = await apiServerGet<ProfileUser | null>("/settings/profile");
  } catch (error) {
    if (error instanceof ApiClientError) {
      if (error.status === 401) {
        redirect("/login");
      }
      if (error.code === "BANNED") {
        redirect(`/login?ban=${encodeURIComponent(error.message)}`);
      }
    }
    throw error;
  }

  if (!currentUser) {
    redirect("/login");
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <SettingsProfileToastTrigger toastType={params.toast} />

        <header className={styles.header}>
          <Link href="/settings" className={styles.backButton} aria-label="Назад в настройки">
            ←
          </Link>
          <h1 className={styles.title}>Профиль</h1>
          <span className={styles.spacer} />
        </header>

        <ProfileEditForm user={currentUser} />
      </div>

      <AppMenu />
    </main>
  );
}
