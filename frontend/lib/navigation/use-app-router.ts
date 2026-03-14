"use client";

import { usePathname, useRouter as useNextRouter, useSearchParams } from "next/navigation";

import { beginTopLoaderNavigation } from "@/lib/top-loader/store";

const getCurrentHref = (pathname: string, searchParams: { toString(): string } | null) => {
  const search = searchParams?.toString();
  return `${pathname}${search ? `?${search}` : ""}`;
};

const normalizeHref = (href: Parameters<ReturnType<typeof useNextRouter>["push"]>[0]) => {
  if (typeof href === "string") {
    return href;
  }

  return null;
};

export function useAppRouter() {
  const router = useNextRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const currentHref = getCurrentHref(pathname, searchParams);

  return {
    ...router,
    push: (href: Parameters<typeof router.push>[0], options?: Parameters<typeof router.push>[1]) => {
      const nextHref = normalizeHref(href);
      if (nextHref !== null && nextHref !== currentHref) {
        beginTopLoaderNavigation();
      }

      router.push(href, options);
    },
    replace: (href: Parameters<typeof router.replace>[0], options?: Parameters<typeof router.replace>[1]) => {
      const nextHref = normalizeHref(href);
      if (nextHref !== null && nextHref !== currentHref) {
        beginTopLoaderNavigation();
      }

      router.replace(href, options);
    },
  };
}
