"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import { apiClientRequest } from "@/lib/api/client";

import styles from "./notifications.module.css";

type ClearNotificationsButtonProps = {
  disabled: boolean;
};

export function ClearNotificationsButton({ disabled }: ClearNotificationsButtonProps) {
  const router = useRouter();
  const [isPending, setIsPending] = useState(false);

  const onClick = async () => {
    if (disabled || isPending) {
      return;
    }

    setIsPending(true);
    try {
      await apiClientRequest("/notifications", {
        method: "DELETE",
        body: JSON.stringify({}),
      });
      router.refresh();
    } finally {
      setIsPending(false);
    }
  };

  return (
    <button className={styles.clearButton} type="button" disabled={disabled || isPending} onClick={onClick}>
      {isPending ? "Очистка..." : "Очистить"}
    </button>
  );
}
