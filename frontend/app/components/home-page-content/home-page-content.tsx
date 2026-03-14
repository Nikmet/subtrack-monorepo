"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { HomeDeleteConfirm } from "@/app/components/home-delete-confirm/home-delete-confirm";
import { apiClientGet, apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";
import type {
  HomeCurrency,
  HomeScreenData,
  SubscriptionListItem,
} from "@/app/types/home";
import { AnalyticsSection } from "../analytics-section/analytics-section";
import { HomeHeader } from "../home-header/home-header";
import {
  HomeSubscriptionEditor,
  type HomeBank,
  type HomePaymentMethod,
} from "../home-subscription-editor/home-subscription-editor";
import { SubscriptionsSection } from "../subscriptions-section/subscriptions-section";
import { SummaryCard } from "../summary-card/summary-card";

import styles from "./home-page-content.module.css";

type HomePageContentProps = {
  initialScreenData: HomeScreenData;
  initialPaymentMethods: HomePaymentMethod[];
  banks: HomeBank[];
};

const sessionCurrencyStorageKey = "subtrack-home-currency";
const allowedCurrencies: HomeCurrency[] = ["rub", "usd", "eur"];

const getNextCurrency = (currency: HomeCurrency): HomeCurrency => {
  if (currency === "rub") {
    return "usd";
  }
  if (currency === "usd") {
    return "eur";
  }

  return "rub";
};

export function HomePageContent({
  initialScreenData,
  initialPaymentMethods,
  banks,
}: HomePageContentProps) {
  const [screenData, setScreenData] = useState(initialScreenData);
  const [paymentMethods, setPaymentMethods] = useState(initialPaymentMethods);
  const [isHomeLoading, setIsHomeLoading] = useState(false);
  const [isDialogSaving, setIsDialogSaving] = useState(false);
  const [isDeleteSubmitting, setIsDeleteSubmitting] = useState(false);
  const [dialogError, setDialogError] = useState<string | null>(null);
  const [editingItem, setEditingItem] = useState<SubscriptionListItem | null>(
    null,
  );
  const [deletingItem, setDeletingItem] = useState<SubscriptionListItem | null>(
    null,
  );

  const applyCurrencyResponse = (
    requestedCurrency: HomeCurrency,
    payload: HomeScreenData,
  ) => {
    setScreenData(payload);

    if (payload.currencyFallback && requestedCurrency !== "rub") {
      sessionStorage.setItem(sessionCurrencyStorageKey, "rub");
      toast.warning(
        "Курс ЦБ РФ временно недоступен. Показаны суммы в рублях.",
      );
      return;
    }

    sessionStorage.setItem(sessionCurrencyStorageKey, payload.currency);
  };

  const loadHome = async (currency: HomeCurrency) => {
    setIsHomeLoading(true);

    try {
      const payload = await apiClientGet<HomeScreenData>(
        `/home?currency=${currency}`,
      );
      applyCurrencyResponse(currency, payload);
    } catch (error) {
      if (error instanceof ApiClientError) {
        toast.error(error.message);
      } else {
        toast.error("Не удалось обновить данные главного экрана.");
      }
    } finally {
      setIsHomeLoading(false);
    }
  };

  const refreshHomeAndPaymentMethods = async () => {
    const [homePayload, paymentMethodsPayload] = await Promise.all([
      apiClientGet<HomeScreenData>(`/home?currency=${screenData.currency}`),
      apiClientGet<HomePaymentMethod[]>("/payment-methods"),
    ]);

    applyCurrencyResponse(screenData.currency, homePayload);
    setPaymentMethods(paymentMethodsPayload);
  };

  useEffect(() => {
    const storedCurrency = sessionStorage.getItem(sessionCurrencyStorageKey);

    if (
      !storedCurrency ||
      !allowedCurrencies.includes(storedCurrency as HomeCurrency)
    ) {
      sessionStorage.setItem(
        sessionCurrencyStorageKey,
        initialScreenData.currency,
      );
      return;
    }

    if (storedCurrency !== initialScreenData.currency) {
      void loadHome(storedCurrency as HomeCurrency);
    }
  }, [initialScreenData.currency]);

  const handleDeleteConfirm = async () => {
    if (!deletingItem) {
      return;
    }

    setIsDeleteSubmitting(true);
    setIsHomeLoading(true);

    try {
      await apiClientRequest(`/user-subscriptions/${deletingItem.id}`, {
        method: "DELETE",
      });
      const payload = await apiClientGet<HomeScreenData>(
        `/home?currency=${screenData.currency}`,
      );
      applyCurrencyResponse(screenData.currency, payload);
      toast.success(`${deletingItem.typeName} удалена.`);
      setDeletingItem(null);
    } catch (error) {
      if (error instanceof ApiClientError) {
        toast.error(error.message);
      } else {
        toast.error("Не удалось удалить подписку.");
      }
    } finally {
      setIsDeleteSubmitting(false);
      setIsHomeLoading(false);
    }
  };

  const handleDialogSubmit = async (payload: {
    nextPaymentAt: string;
    paymentMethodId: string;
    newPaymentMethodBankId: string;
    newPaymentMethodCardNumber: string;
  }) => {
    if (!editingItem) {
      return;
    }

    setIsDialogSaving(true);
    setDialogError(null);

    try {
      await apiClientRequest(`/user-subscriptions/${editingItem.id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });
      await refreshHomeAndPaymentMethods();
      toast.success(`${editingItem.typeName} обновлена.`);
      setEditingItem(null);
    } catch (error) {
      if (error instanceof ApiClientError) {
        setDialogError(error.message);
      } else {
        setDialogError("Не удалось обновить подписку.");
      }
    } finally {
      setIsDialogSaving(false);
    }
  };

  return (
    <>
      <main className={styles.page}>
        <div className={styles.container}>
          <HomeHeader
            userInitials={screenData.userInitials}
            userAvatarLink={screenData.userAvatarLink}
          />

          <div className={styles.layout}>
            <div className={styles.leftColumn}>
              <SummaryCard
                monthlyTotal={screenData.monthlyTotal}
                subscriptionsCount={screenData.subscriptionsCount}
                currency={screenData.currency}
                isLoading={isHomeLoading}
                onCurrencyCycle={() => {
                  if (isHomeLoading) {
                    return;
                  }

                  void loadHome(getNextCurrency(screenData.currency));
                }}
              />
              <SubscriptionsSection
                subscriptions={screenData.subscriptions}
                currency={screenData.currency}
                onEdit={(item) => {
                  setDialogError(null);
                  setEditingItem(item);
                }}
                onDelete={(item) => setDeletingItem(item)}
                isBusy={isHomeLoading}
              />
            </div>

            <AnalyticsSection
              categoryStats={screenData.categoryStats}
              categoryTotal={screenData.categoryTotal}
              cardStats={screenData.cardStats}
              cardTotal={screenData.cardTotal}
              currency={screenData.currency}
            />
          </div>
        </div>

        <AppMenu />
      </main>

      {editingItem ? (
        <HomeSubscriptionEditor
          item={editingItem}
          currency={screenData.currency}
          paymentMethods={paymentMethods}
          banks={banks}
          isSubmitting={isDialogSaving}
          errorMessage={dialogError}
          onClose={() => {
            if (!isDialogSaving) {
              setEditingItem(null);
              setDialogError(null);
            }
          }}
          onSubmit={(payload) => void handleDialogSubmit(payload)}
        />
      ) : null}

      {deletingItem ? (
        <HomeDeleteConfirm
          subscriptionName={deletingItem.typeName}
          isSubmitting={isDeleteSubmitting}
          onClose={() => {
            if (!isDeleteSubmitting) {
              setDeletingItem(null);
            }
          }}
          onConfirm={() => void handleDeleteConfirm()}
        />
      ) : null}
    </>
  );
}
