import { redirect } from "next/navigation";

import { HomePageContent } from "@/app/components/home-page-content/home-page-content";
import type { HomeBank, HomePaymentMethod } from "@/app/components/home-subscription-editor/home-subscription-editor";
import { HomeToastTrigger } from "@/app/components/toast/home-toast-trigger";
import type { HomeScreenData } from "@/app/types/home";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

export const dynamic = "force-dynamic";

type HomePageProps = {
  searchParams: Promise<{
    toast?: string;
    name?: string;
  }>;
};

export default async function HomePage({ searchParams }: HomePageProps) {
  let screenData: HomeScreenData | null = null;
  let paymentMethods: HomePaymentMethod[] = [];
  let banks: HomeBank[] = [];

  try {
    [screenData, paymentMethods, banks] = await Promise.all([
      apiServerGet<HomeScreenData | null>("/home"),
      apiServerGet<HomePaymentMethod[]>("/payment-methods"),
      apiServerGet<HomeBank[]>("/banks"),
    ]);
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

  if (!screenData) {
    redirect("/login");
  }

  const params = await searchParams;

  return (
    <>
      <HomeToastTrigger toastType={params.toast} name={params.name} />
      <HomePageContent initialScreenData={screenData} initialPaymentMethods={paymentMethods} banks={banks} />
    </>
  );
}
