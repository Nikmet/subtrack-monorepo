"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import { apiClientRequest } from "@/lib/api/client";

type LogoutButtonProps = {
  className: string;
  text?: string;
};

export function LogoutButton({ className, text = "Выйти из аккаунта" }: LogoutButtonProps) {
  const router = useRouter();
  const [isPending, setIsPending] = useState(false);

  const onClick = async () => {
    if (isPending) {
      return;
    }

    setIsPending(true);
    try {
      await apiClientRequest("/auth/logout", {
        method: "POST",
        body: JSON.stringify({}),
      });
    } finally {
      router.replace("/login");
      router.refresh();
      setIsPending(false);
    }
  };

  return (
    <button className={className} type="button" onClick={onClick} disabled={isPending}>
      {isPending ? "Выход..." : text}
    </button>
  );
}
