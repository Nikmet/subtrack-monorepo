"use client";

import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { usePathname, useSearchParams } from "next/navigation";

import {
  completeTopLoaderNavigation,
  getTopLoaderSnapshot,
  subscribeTopLoader,
  type TopLoaderSnapshot,
  beginTopLoaderNavigation,
} from "@/lib/top-loader/store";

import styles from "./top-loader-provider.module.css";

export function TopLoaderProvider() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [snapshot, setSnapshot] = useState<TopLoaderSnapshot>(getTopLoaderSnapshot());
  const [isVisible, setIsVisible] = useState(false);
  const [progress, setProgress] = useState(0);
  const finishTimeoutRef = useRef<number | null>(null);

  useEffect(() => {
    const unsubscribe = subscribeTopLoader(() => {
      setSnapshot(getTopLoaderSnapshot());
    });

    return () => {
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    completeTopLoaderNavigation();
  }, [pathname, searchParams]);

  useEffect(() => {
    const onDocumentClick = (event: MouseEvent) => {
      if (
        event.defaultPrevented ||
        event.button !== 0 ||
        event.metaKey ||
        event.ctrlKey ||
        event.shiftKey ||
        event.altKey
      ) {
        return;
      }

      const target = event.target;
      if (!(target instanceof Element)) {
        return;
      }

      const anchor = target.closest("a[href]");
      if (!(anchor instanceof HTMLAnchorElement)) {
        return;
      }

      if (anchor.target && anchor.target !== "_self") {
        return;
      }

      if (anchor.hasAttribute("download")) {
        return;
      }

      if (anchor.dataset.topLoader === "ignore") {
        return;
      }

      const nextUrl = new URL(anchor.href, window.location.href);
      const currentUrl = new URL(window.location.href);

      if (nextUrl.origin !== currentUrl.origin) {
        return;
      }

      if (
        nextUrl.pathname === currentUrl.pathname &&
        nextUrl.search === currentUrl.search
      ) {
        return;
      }

      beginTopLoaderNavigation();
    };

    document.addEventListener("click", onDocumentClick, true);
    return () => document.removeEventListener("click", onDocumentClick, true);
  }, []);

  const pendingCount = useMemo(
    () => snapshot.requestCount + snapshot.navigationCount,
    [snapshot.navigationCount, snapshot.requestCount],
  );

  useEffect(() => {
    if (finishTimeoutRef.current !== null) {
      window.clearTimeout(finishTimeoutRef.current);
      finishTimeoutRef.current = null;
    }

    if (pendingCount > 0) {
      setIsVisible(true);
      setProgress((currentValue) => (currentValue <= 0 ? 12 : Math.max(currentValue, 12)));
      return;
    }

    if (!isVisible) {
      return;
    }

    setProgress(100);
    finishTimeoutRef.current = window.setTimeout(() => {
      setIsVisible(false);
      setProgress(0);
      finishTimeoutRef.current = null;
    }, 220);
  }, [isVisible, pendingCount]);

  useEffect(() => {
    if (!isVisible || pendingCount === 0) {
      return;
    }

    const interval = window.setInterval(() => {
      setProgress((currentValue) => {
        if (currentValue >= 92) {
          return currentValue;
        }

        const nextValue = currentValue + Math.max((94 - currentValue) * 0.18, 2.5);
        return Math.min(92, nextValue);
      });
    }, 180);

    return () => window.clearInterval(interval);
  }, [isVisible, pendingCount]);

  return (
    <div
      className={`${styles.loader} ${isVisible ? styles.loaderVisible : ""}`}
      aria-hidden
    >
      <span
        className={styles.bar}
        style={{ "--loader-progress": `${progress}%` } as CSSProperties}
      />
    </div>
  );
}
