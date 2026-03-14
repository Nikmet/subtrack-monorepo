"use client";

import { useRouter } from "@/lib/navigation/client";
import { useMemo, useState, type FormEvent } from "react";

import { formatPaymentMethodLabel } from "@/app/utils/payment-method-formatters";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "./payment-methods.module.css";

type Bank = {
  id: string;
  name: string;
  iconLink: string;
};

type PaymentMethod = {
  id: string;
  cardNumber: string;
  bankId: string;
  isDefault: boolean;
  bank: {
    name: string;
    iconLink: string;
  };
  _count: {
    subscriptions: number;
  };
};

type PaymentMethodsClientProps = {
  banks: Bank[];
  paymentMethods: PaymentMethod[];
};

const toPage = (toastType: string, name?: string) => {
  const params = new URLSearchParams({ toast: toastType });
  if (name) {
    params.set("name", name);
  }
  return `/settings/payment-methods?${params.toString()}`;
};

export function PaymentMethodsClient({ banks, paymentMethods }: PaymentMethodsClientProps) {
  const router = useRouter();
  const hasBanks = banks.length > 0;
  const [pendingId, setPendingId] = useState<string | null>(null);
  const [isCreating, setIsCreating] = useState(false);

  const defaultBankId = useMemo(() => banks[0]?.id ?? "", [banks]);

  const pushToast = (toast: string, name?: string) => {
    router.push(toPage(toast, name));
    router.refresh();
  };

  const mapErrorToast = (error: ApiClientError) => {
    if (error.code === "PAYMENT_METHOD_EXISTS") {
      return "exists";
    }

    if (error.code === "PAYMENT_METHOD_IN_USE") {
      return "used";
    }

    if (error.code === "NOT_FOUND") {
      return "forbidden";
    }

    return "invalid";
  };

  const onCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const bankId = typeof formData.get("bankId") === "string" ? formData.get("bankId")!.toString() : "";
    const cardNumber =
      typeof formData.get("cardNumber") === "string" ? formData.get("cardNumber")!.toString() : "";

    setIsCreating(true);
    try {
      await apiClientRequest<{ label: string }>("/payment-methods", {
        method: "POST",
        body: JSON.stringify({ bankId, cardNumber }),
      });
      const bankName = banks.find((item) => item.id === bankId)?.name ?? "Банк";
      pushToast("created", formatPaymentMethodLabel(bankName, cardNumber));
    } catch (error) {
      if (error instanceof ApiClientError) {
        pushToast(mapErrorToast(error));
      } else {
        pushToast("invalid");
      }
    } finally {
      setIsCreating(false);
    }
  };

  const onUpdate =
    (methodId: string) =>
    async (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const formData = new FormData(event.currentTarget);
      const bankId = typeof formData.get("bankId") === "string" ? formData.get("bankId")!.toString() : "";
      const cardNumber =
        typeof formData.get("cardNumber") === "string" ? formData.get("cardNumber")!.toString() : "";

      setPendingId(methodId);
      try {
        await apiClientRequest(`/payment-methods/${methodId}`, {
          method: "PATCH",
          body: JSON.stringify({ bankId, cardNumber }),
        });
        const bankName = banks.find((item) => item.id === bankId)?.name ?? "Банк";
        pushToast("updated", formatPaymentMethodLabel(bankName, cardNumber));
      } catch (error) {
        if (error instanceof ApiClientError) {
          pushToast(mapErrorToast(error));
        } else {
          pushToast("invalid");
        }
      } finally {
        setPendingId(null);
      }
    };

  const onSetDefault = async (method: PaymentMethod) => {
    setPendingId(method.id);
    try {
      await apiClientRequest(`/payment-methods/${method.id}/default`, {
        method: "PATCH",
        body: JSON.stringify({}),
      });
      pushToast("default", formatPaymentMethodLabel(method.bank.name, method.cardNumber));
    } catch (error) {
      if (error instanceof ApiClientError) {
        pushToast(mapErrorToast(error));
      } else {
        pushToast("invalid");
      }
    } finally {
      setPendingId(null);
    }
  };

  const onDelete = async (method: PaymentMethod) => {
    setPendingId(method.id);
    try {
      await apiClientRequest(`/payment-methods/${method.id}`, {
        method: "DELETE",
        body: JSON.stringify({}),
      });
      pushToast("deleted", formatPaymentMethodLabel(method.bank.name, method.cardNumber));
    } catch (error) {
      if (error instanceof ApiClientError) {
        pushToast(mapErrorToast(error));
      } else {
        pushToast("invalid");
      }
    } finally {
      setPendingId(null);
    }
  };

  return (
    <>
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Новый способ оплаты</h2>
        {hasBanks ? (
          <form onSubmit={onCreate} className={styles.createForm}>
            <select name="bankId" className={styles.input} defaultValue={defaultBankId} required>
              {banks.map((bank) => (
                <option key={bank.id} value={bank.id}>
                  {bank.name}
                </option>
              ))}
            </select>
            <input
              name="cardNumber"
              className={styles.input}
              type="text"
              placeholder="Номер карты, например **** 4242"
              minLength={4}
              maxLength={24}
              required
            />
            <button className={styles.primaryButton} type="submit" disabled={isCreating}>
              {isCreating ? "Создание..." : "Создать"}
            </button>
          </form>
        ) : (
          <p className={styles.emptyText}>Банки не настроены. Добавьте их в админ-панели.</p>
        )}
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Мои карты</h2>
        {paymentMethods.length === 0 ? (
          <p className={styles.emptyText}>Сохраненных способов оплаты пока нет.</p>
        ) : (
          <div className={styles.methodsList}>
            {paymentMethods.map((method) => (
              <article key={method.id} className={styles.methodCard}>
                <div className={styles.methodHead}>
                  <div className={styles.bankSummary}>
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={method.bank.iconLink} alt={method.bank.name} className={styles.bankIcon} />
                    <p className={styles.methodLabel}>{formatPaymentMethodLabel(method.bank.name, method.cardNumber)}</p>
                  </div>
                  {method.isDefault ? <span className={styles.defaultBadge}>По умолчанию</span> : null}
                </div>
                <p className={styles.methodMeta}>Подписок: {method._count.subscriptions}</p>

                {hasBanks ? (
                  <form onSubmit={onUpdate(method.id)} className={styles.inlineForm}>
                    <select name="bankId" className={styles.input} defaultValue={method.bankId} required>
                      {banks.map((bank) => (
                        <option key={bank.id} value={bank.id}>
                          {bank.name}
                        </option>
                      ))}
                    </select>
                    <input
                      name="cardNumber"
                      className={styles.input}
                      type="text"
                      defaultValue={method.cardNumber}
                      minLength={4}
                      maxLength={24}
                      required
                    />
                    <button className={styles.secondaryButton} type="submit" disabled={pendingId === method.id}>
                      {pendingId === method.id ? "Сохранение..." : "Сохранить"}
                    </button>
                  </form>
                ) : null}

                <div className={styles.actionsRow}>
                  {!method.isDefault ? (
                    <button
                      type="button"
                      className={styles.secondaryButton}
                      onClick={() => onSetDefault(method)}
                      disabled={pendingId === method.id}
                    >
                      {pendingId === method.id ? "Сохранение..." : "Сделать основным"}
                    </button>
                  ) : null}

                  <button
                    type="button"
                    className={styles.deleteButton}
                    onClick={() => onDelete(method)}
                    disabled={pendingId === method.id}
                  >
                    {pendingId === method.id ? "Удаление..." : "Удалить"}
                  </button>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </>
  );
}
