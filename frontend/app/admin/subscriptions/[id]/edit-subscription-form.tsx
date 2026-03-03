"use client";

import { useRouter } from "next/navigation";
import { useState, type ChangeEvent, type FormEvent } from "react";

import { SUBSCRIPTION_CATEGORIES } from "@/app/constants/subscription-categories";
import { API_V1_PREFIX, getApiUrl } from "@/lib/api/config";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "./edit-subscription.module.css";

type EditSubscriptionFormProps = {
  item: {
    id: string;
    name: string;
    imgLink: string;
    category: (typeof SUBSCRIPTION_CATEGORIES)[number]["value"];
    price: number;
    period: number;
    moderationComment: string | null;
  };
};

export function EditSubscriptionForm({ item }: EditSubscriptionFormProps) {
  const router = useRouter();
  const [name, setName] = useState(item.name);
  const [iconUrl, setIconUrl] = useState(item.imgLink);
  const [category, setCategory] = useState(item.category);
  const [price, setPrice] = useState(String(item.price));
  const [period, setPeriod] = useState(String(item.period));
  const [moderationComment, setModerationComment] = useState(item.moderationComment ?? "");
  const [isUploading, setIsUploading] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    if (file.size > 10 * 1024 * 1024) {
      setUploadError("Размер файла иконки не должен превышать 10MB.");
      return;
    }

    setUploadError(null);
    setIsUploading(true);

    try {
      const formData = new FormData();
      formData.append("file", file);

      const response = await fetch(getApiUrl(`${API_V1_PREFIX}/uploads/icon`), {
        method: "POST",
        credentials: "include",
        body: formData,
      });

      const json = (await response.json()) as { data?: { url?: string }; error?: { message?: string } };
      if (!response.ok || !json.data?.url) {
        setUploadError(json.error?.message ?? "Не удалось загрузить иконку.");
        return;
      }

      setIconUrl(json.data.url);
    } catch {
      setUploadError("Ошибка загрузки. Попробуйте снова.");
    } finally {
      setIsUploading(false);
    }
  };

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsPending(true);
    setFormError(null);

    try {
      await apiClientRequest(`/admin/subscriptions/${item.id}`, {
        method: "PATCH",
        body: JSON.stringify({
          name: name.trim(),
          imgLink: iconUrl.trim(),
          category,
          price: Number(price),
          period: Number(period),
          moderationComment: moderationComment.trim() || null,
        }),
      });
      router.push("/admin/published");
      router.refresh();
    } catch (error) {
      if (error instanceof ApiClientError) {
        setFormError(error.message);
      } else {
        setFormError("Не удалось сохранить изменения.");
      }
    } finally {
      setIsPending(false);
    }
  };

  return (
    <form onSubmit={onSubmit} className={styles.form}>
      <div className={styles.iconField}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={iconUrl} alt="Иконка подписки" className={styles.iconPreview} />
        <label className={styles.uploadLabel} htmlFor="iconUpload">
          {isUploading ? "Загрузка..." : "Загрузить иконку"}
        </label>
        <input
          id="iconUpload"
          type="file"
          accept="image/png,image/jpeg,image/webp,image/svg+xml"
          className={styles.fileInput}
          onChange={handleFileChange}
        />
        {uploadError ? <p className={styles.uploadError}>{uploadError}</p> : null}
      </div>

      <label className={styles.label} htmlFor="name">
        Название
      </label>
      <input
        className={styles.input}
        id="name"
        name="name"
        value={name}
        onChange={(event) => setName(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="imgLink">
        URL иконки
      </label>
      <input
        className={styles.input}
        id="imgLink"
        name="imgLink"
        value={iconUrl}
        onChange={(event) => setIconUrl(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="category">
        Категория
      </label>
      <select
        className={styles.input}
        id="category"
        name="category"
        value={category}
        onChange={(event) => setCategory(event.target.value as typeof category)}
        required
      >
        {SUBSCRIPTION_CATEGORIES.map((entry) => (
          <option key={entry.value} value={entry.value}>
            {entry.label}
          </option>
        ))}
      </select>

      <label className={styles.label} htmlFor="price">
        Стоимость
      </label>
      <input
        className={styles.input}
        id="price"
        type="number"
        name="price"
        step="0.01"
        min="0.01"
        value={price}
        onChange={(event) => setPrice(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="period">
        Период
      </label>
      <select
        className={styles.input}
        id="period"
        name="period"
        value={period}
        onChange={(event) => setPeriod(event.target.value)}
        required
      >
        <option value="1">Ежемесячно</option>
        <option value="3">Раз в 3 месяца</option>
        <option value="6">Раз в 6 месяцев</option>
        <option value="12">Раз в год</option>
      </select>

      <label className={styles.label} htmlFor="moderationComment">
        Комментарий модератора
      </label>
      <textarea
        className={styles.textarea}
        id="moderationComment"
        name="moderationComment"
        value={moderationComment}
        onChange={(event) => setModerationComment(event.target.value)}
        rows={3}
      />

      {formError ? <p className={styles.uploadError}>{formError}</p> : null}

      <button className={styles.submitButton} type="submit" disabled={isPending || isUploading}>
        {isPending ? "Сохранение..." : "Сохранить изменения"}
      </button>
    </form>
  );
}
