"use client";

import { useRouter } from "@/lib/navigation/client";
import { useState, type ChangeEvent, type FormEvent } from "react";

import { SUBSCRIPTION_CATEGORIES } from "@/app/constants/subscription-categories";
import { API_V1_PREFIX, getApiUrl } from "@/lib/api/config";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";
import styles from "./new-subscription-form.module.css";

const periods = [
  { value: "1", label: "Ежемесячно" },
  { value: "3", label: "Раз в 3 месяца" },
  { value: "6", label: "Раз в 6 месяцев" },
  { value: "12", label: "Раз в год" },
];

export function NewSubscriptionForm() {
  const router = useRouter();
  const [iconUrl, setIconUrl] = useState("");
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isPending, setIsPending] = useState(false);

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
    const formData = new FormData(event.currentTarget);

    const name = typeof formData.get("name") === "string" ? formData.get("name")!.toString().trim() : "";
    const category = typeof formData.get("category") === "string" ? formData.get("category")!.toString() : "other";
    const managementUrl =
      typeof formData.get("managementUrl") === "string" ? formData.get("managementUrl")!.toString().trim() : "";
    const price = typeof formData.get("price") === "string" ? Number(formData.get("price")) : 0;
    const period = typeof formData.get("period") === "string" ? Number(formData.get("period")) : 1;

    setError(null);
    setIsPending(true);
    try {
      await apiClientRequest("/common-subscriptions", {
        method: "POST",
        body: JSON.stringify({
          name,
          category,
          imgLink: iconUrl,
          managementUrl,
          price,
          period,
        }),
      });
      router.push(`/subscriptions/pending?toast=submitted&name=${encodeURIComponent(name)}`);
      router.refresh();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось создать подписку.");
      }
    } finally {
      setIsPending(false);
    }
  };

  return (
    <form onSubmit={onSubmit} className={styles.form}>
      <input type="hidden" name="imgLink" value={iconUrl} />

      <section className={styles.identitySection}>
        <div className={styles.iconField}>
          <label className={styles.iconDrop} htmlFor="iconUpload">
            {iconUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={iconUrl} alt="Иконка подписки" className={styles.iconPreview} />
            ) : (
              <span className={styles.iconPlaceholder}>Иконка</span>
            )}
          </label>
          <input
            id="iconUpload"
            type="file"
            accept="image/png,image/jpeg,image/webp,image/svg+xml"
            className={styles.fileInput}
            onChange={handleFileChange}
          />
          <p className={styles.iconHint}>{isUploading ? "Загрузка..." : "Нажмите, чтобы загрузить иконку"}</p>
          <p className={styles.iconSubtext}>Поддерживаются PNG, JPG, WEBP и SVG до 10MB.</p>
          {uploadError ? <p className={styles.errorText}>{uploadError}</p> : null}
        </div>

        <div className={styles.identityContent}>
          <div className={styles.sectionHeader}>
            <p className={styles.sectionEyebrow}>Основа карточки</p>
            <h3 className={styles.sectionTitle}>Как сервис будет выглядеть в каталоге</h3>
            <p className={styles.sectionText}>
              Название и категория нужны для поиска, а качественная иконка делает карточку узнаваемой.
            </p>
          </div>

          <div className={styles.fieldGrid}>
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="name">
                Название сервиса
              </label>
              <input id="name" className={styles.input} type="text" name="name" placeholder="Напр. Netflix" required />
            </div>

            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="category">
                Категория
              </label>
              <select id="category" className={styles.input} name="category" defaultValue="other" required>
                {SUBSCRIPTION_CATEGORIES.map((category) => (
                  <option key={category.value} value={category.value}>
                    {category.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </section>

      <section className={styles.sectionCard}>
        <div className={styles.sectionHeader}>
          <p className={styles.sectionEyebrow}>Платежные параметры</p>
          <h3 className={styles.sectionTitle}>Настройте стоимость и период списания</h3>
          <p className={styles.sectionText}>
            Укажите ту цену, которую пользователь реально платит за один цикл подписки.
          </p>
        </div>

        <div className={styles.rowFields}>
          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="price">
              Стоимость
            </label>
            <div className={styles.inputWrap}>
              <input
                id="price"
                className={styles.input}
                type="number"
                step="0.01"
                min="0.01"
                name="price"
                placeholder="0.00"
                required
              />
              <span className={styles.inputSuffix}>₽</span>
            </div>
          </div>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="period">
              Период
            </label>
            <select id="period" className={styles.input} name="period" defaultValue="1" required>
              {periods.map((period) => (
                <option key={period.value} value={period.value}>
                  {period.label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </section>

      <section className={styles.sectionCard}>
        <div className={styles.sectionHeader}>
          <p className={styles.sectionEyebrow}>Опционально</p>
          <h3 className={styles.sectionTitle}>Ссылка на управление подпиской</h3>
          <p className={styles.sectionText}>
            Если у сервиса есть личный кабинет или страница управления, добавьте ссылку. Она появится на
            карточке подписки у пользователя.
          </p>
        </div>

        <div className={styles.fieldGroup}>
          <label className={styles.label} htmlFor="managementUrl">
            Ссылка на управление
          </label>
          <input
            id="managementUrl"
            className={styles.input}
            type="url"
            name="managementUrl"
            placeholder="https://..."
          />
        </div>
      </section>

      {error ? <p className={styles.errorText}>{error}</p> : null}

      <div className={styles.submitRow}>
        <p className={styles.submitHint}>
          После отправки заявка попадет на модерацию. Как только она будет опубликована, сервис появится в
          общем каталоге.
        </p>

        <button className={styles.submitButton} type="submit" disabled={isPending || isUploading}>
          {isPending ? "Отправка..." : "Создать подписку"}
        </button>
      </div>
    </form>
  );
}
