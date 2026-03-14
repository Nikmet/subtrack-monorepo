"use client";

import { useRouter } from "@/lib/navigation/client";
import { useState, type ChangeEvent, type FormEvent } from "react";

import { UserAvatar } from "@/app/components/user-avatar/user-avatar";
import { API_V1_PREFIX, getApiUrl } from "@/lib/api/config";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "./profile.module.css";

type ProfileEditFormProps = {
  user: {
    name: string;
    email: string;
    avatarLink: string | null;
  };
};

const getInitials = (name: string) =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");

export function ProfileEditForm({ user }: ProfileEditFormProps) {
  const router = useRouter();
  const [avatarLink, setAvatarLink] = useState(user.avatarLink ?? "");
  const [name, setName] = useState(user.name);
  const [email, setEmail] = useState(user.email);
  const [isUploading, setIsUploading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [errorText, setErrorText] = useState<string | null>(null);

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    if (file.size > 10 * 1024 * 1024) {
      setErrorText("Размер файла аватара не должен превышать 10MB.");
      return;
    }

    setErrorText(null);
    setIsUploading(true);

    try {
      const formData = new FormData();
      formData.append("file", file);

      const response = await fetch(getApiUrl(`${API_V1_PREFIX}/uploads/avatar`), {
        method: "POST",
        credentials: "include",
        body: formData,
      });

      const json = (await response.json()) as { data?: { url?: string }; error?: { message?: string } };
      if (!response.ok || !json.data?.url) {
        setErrorText(json.error?.message ?? "Не удалось загрузить аватар.");
        return;
      }

      setAvatarLink(json.data.url);
    } catch {
      setErrorText("Ошибка загрузки. Попробуйте снова.");
    } finally {
      setIsUploading(false);
    }
  };

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setErrorText(null);
    setIsSaving(true);
    try {
      await apiClientRequest("/settings/profile", {
        method: "PATCH",
        body: JSON.stringify({
          name: name.trim(),
          email: email.trim().toLowerCase(),
          avatarLink: avatarLink.trim() || null,
        }),
      });
      router.push("/settings/profile?toast=saved");
      router.refresh();
    } catch (error) {
      if (error instanceof ApiClientError) {
        if (error.code === "CONFLICT") {
          router.push("/settings/profile?toast=email_exists");
        } else {
          router.push("/settings/profile?toast=invalid");
        }
      } else {
        router.push("/settings/profile?toast=invalid");
      }
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <form onSubmit={onSubmit} className={styles.form}>
      <div className={styles.avatarSection}>
        <UserAvatar
          src={avatarLink}
          name={name}
          wrapperClassName={styles.avatarWrap}
          imageClassName={styles.avatarImage}
          fallbackClassName={styles.avatarFallback}
          fallbackText={getInitials(name) || "?"}
        />

        <label className={styles.uploadButton} htmlFor="avatarUpload">
          {isUploading ? "Загрузка..." : "Загрузить аватар"}
        </label>
        <input
          id="avatarUpload"
          type="file"
          accept="image/png,image/jpeg,image/webp,image/svg+xml"
          className={styles.fileInput}
          onChange={handleFileChange}
        />
        {errorText ? <p className={styles.errorText}>{errorText}</p> : null}
      </div>

      <label className={styles.label} htmlFor="name">
        Имя
      </label>
      <input
        id="name"
        className={styles.input}
        name="name"
        type="text"
        minLength={2}
        value={name}
        onChange={(event) => setName(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="email">
        Email
      </label>
      <input
        id="email"
        className={styles.input}
        name="email"
        type="email"
        value={email}
        onChange={(event) => setEmail(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="avatarLink">
        URL аватара
      </label>
      <input
        id="avatarLink"
        className={styles.input}
        name="avatarLink"
        type="url"
        value={avatarLink}
        onChange={(event) => setAvatarLink(event.target.value)}
        placeholder="https://..."
      />

      <button className={styles.submitButton} type="submit" disabled={isSaving || isUploading}>
        {isSaving ? "Сохранение..." : "Сохранить"}
      </button>
    </form>
  );
}
