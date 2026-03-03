"use client";

import { useId, useState, type ChangeEvent, type FormEvent } from "react";

import { API_V1_PREFIX, getApiUrl } from "@/lib/api/config";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "../admin.module.css";

type BankItem = {
  id: string;
  name: string;
  iconLink: string;
  _count: {
    paymentMethods: number;
  };
};

type BankFormState = {
  name: string;
  iconLink: string;
};

type BankFormCardProps = {
  initial: BankFormState;
  bankId?: string;
  onSubmit: (payload: BankFormState) => Promise<void>;
  submitLabel: string;
  pendingLabel: string;
  submitClassName: string;
};

const getFallbackLetter = (value: string) => {
  const trimmed = value.trim();
  if (!trimmed) {
    return "?";
  }

  const first = Array.from(trimmed)[0];
  return first ? first.toLocaleUpperCase("ru-RU") : "?";
};

function BankFormCard({ initial, onSubmit, submitLabel, pendingLabel, submitClassName }: BankFormCardProps) {
  const [name, setName] = useState(initial.name);
  const [iconLink, setIconLink] = useState(initial.iconLink);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const fileInputId = useId();

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

      setIconLink(json.data.url);
    } catch {
      setUploadError("Ошибка загрузки. Попробуйте снова.");
    } finally {
      setIsUploading(false);
    }
  };

  const onSubmitInternal = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsPending(true);
    try {
      await onSubmit({ name: name.trim(), iconLink: iconLink.trim() });
    } finally {
      setIsPending(false);
    }
  };

  const showImage = iconLink.trim().length > 0;

  return (
    <form onSubmit={onSubmitInternal} className={styles.inlineForm}>
      <div className={styles.uploadField}>
        <div className={styles.uploadPreviewWrap}>
          {showImage ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={iconLink} alt={name || "Иконка банка"} className={styles.uploadPreviewImage} />
          ) : (
            <span className={styles.uploadPreviewFallback}>{getFallbackLetter(name)}</span>
          )}
        </div>

        <label className={styles.uploadButton} htmlFor={fileInputId}>
          {isUploading ? "Загрузка..." : "Загрузить иконку"}
        </label>
        <input
          id={fileInputId}
          type="file"
          accept="image/png,image/jpeg,image/webp,image/svg+xml"
          className={styles.fileInput}
          onChange={handleFileChange}
        />
      </div>

      {uploadError ? <p className={styles.uploadError}>{uploadError}</p> : null}

      <input
        className={styles.input}
        name="name"
        type="text"
        placeholder="Название банка"
        minLength={2}
        value={name}
        onChange={(event) => setName(event.target.value)}
        required
      />
      <input
        className={styles.input}
        name="iconLink"
        type="url"
        placeholder="URL иконки"
        value={iconLink}
        onChange={(event) => setIconLink(event.target.value)}
        required
      />
      <button className={submitClassName} type="submit" disabled={isPending || isUploading}>
        {isPending ? pendingLabel : submitLabel}
      </button>
    </form>
  );
}

type BanksClientProps = {
  banks: BankItem[];
};

export function BanksClient({ banks }: BanksClientProps) {
  const [error, setError] = useState<string | null>(null);
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);

  const reload = () => {
    window.location.reload();
  };

  const createBank = async (payload: BankFormState) => {
    setError(null);
    try {
      await apiClientRequest("/admin/banks", {
        method: "POST",
        body: JSON.stringify(payload),
      });
      reload();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось создать банк.");
      }
    }
  };

  const updateBank = (id: string) => async (payload: BankFormState) => {
    setError(null);
    try {
      await apiClientRequest(`/admin/banks/${id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });
      reload();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось обновить банк.");
      }
    }
  };

  const deleteBank = async (id: string) => {
    setError(null);
    setPendingDeleteId(id);
    try {
      await apiClientRequest(`/admin/banks/${id}`, {
        method: "DELETE",
        body: JSON.stringify({}),
      });
      reload();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось удалить банк.");
      }
    } finally {
      setPendingDeleteId(null);
    }
  };

  return (
    <>
      {error ? <p className={styles.emptyText}>{error}</p> : null}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Новый банк</h2>
        <BankFormCard
          initial={{ name: "", iconLink: "" }}
          onSubmit={createBank}
          submitClassName={styles.publishButton}
          submitLabel="Создать банк"
          pendingLabel="Создание..."
        />
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Справочник</h2>
        {banks.length === 0 ? (
          <p className={styles.emptyText}>Банки пока не добавлены.</p>
        ) : (
          <div className={styles.grid}>
            {banks.map((bank) => (
              <article key={bank.id} className={styles.card}>
                <div className={styles.cardTopRow}>
                  <div className={styles.cardIconWrap}>
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={bank.iconLink} alt={bank.name} className={styles.cardIconImage} />
                  </div>
                  <p className={styles.cardTitle}>{bank.name}</p>
                </div>
                <p className={styles.cardSubMeta}>Используется в {bank._count.paymentMethods} способах оплаты</p>

                <BankFormCard
                  initial={{ name: bank.name, iconLink: bank.iconLink }}
                  onSubmit={updateBank(bank.id)}
                  submitClassName={styles.editLink}
                  submitLabel="Сохранить"
                  pendingLabel="Сохранение..."
                />

                <button
                  type="button"
                  className={styles.deleteButton}
                  onClick={() => deleteBank(bank.id)}
                  disabled={pendingDeleteId === bank.id}
                >
                  {pendingDeleteId === bank.id ? "Удаление..." : "Удалить"}
                </button>
              </article>
            ))}
          </div>
        )}
      </section>
    </>
  );
}
