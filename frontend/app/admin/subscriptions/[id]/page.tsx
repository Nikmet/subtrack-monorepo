import Link from "next/link";
import { notFound } from "next/navigation";

import { requireAdminUser } from "@/lib/auth-guards";
import { apiServerGet } from "@/lib/api/server";

import { EditSubscriptionForm } from "./edit-subscription-form";
import styles from "./edit-subscription.module.css";

export const dynamic = "force-dynamic";

type AdminEditSubscriptionPageProps = {
  params: Promise<{
    id: string;
  }>;
};

type SubscriptionItem = {
  id: string;
  name: string;
  imgLink: string;
  managementUrl: string | null;
  category: "streaming" | "music" | "games" | "shopping" | "ai" | "finance" | "other";
  price: number;
  period: number;
  moderationComment: string | null;
  status: "PENDING" | "PUBLISHED" | "REJECTED";
};

export default async function AdminEditSubscriptionPage({ params }: AdminEditSubscriptionPageProps) {
  await requireAdminUser();

  const { id } = await params;
  const item = await apiServerGet<SubscriptionItem | null>(`/admin/subscriptions/${id}`);

  if (!item) {
    notFound();
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <header className={styles.header}>
          <Link href="/admin/published" className={styles.backLink}>
            {"<- Back to published"}
          </Link>
          <h1 className={styles.title}>Edit subscription</h1>
        </header>

        <EditSubscriptionForm
          item={{
            id: item.id,
            name: item.name,
            imgLink: item.imgLink,
            managementUrl: item.managementUrl,
            category: item.category,
            price: item.price,
            period: item.period,
            moderationComment: item.moderationComment,
          }}
        />
      </div>
    </main>
  );
}
