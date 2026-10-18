"use client";

import { createContext, useCallback, useContext, useRef, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

interface DocsUIContextValue {
  isDocsPage: boolean;
  setIsDocsPage: (value: boolean) => void;
  mobileMenuOpen: boolean;
  setMobileMenuOpen: (value: boolean) => void;
  searchOpen: boolean;
  setSearchOpen: (open: boolean) => void;
  openDocsSearch: () => void;
  /** The mounted docs page registers how to switch pages in place; null on unmount. */
  registerDocsNavigate: (fn: ((pageId: string, tabId?: string) => void) | null) => void;
  /** Opens a docs page: in place on /docs, otherwise by navigating to /docs?page=...&tab=... */
  navigateDocs: (pageId: string, tabId?: string) => void;
}

const DocsUIContext = createContext<DocsUIContextValue | null>(null);

export function DocsUIProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [isDocsPage, setIsDocsPage] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const docsNavigateRef = useRef<((pageId: string, tabId?: string) => void) | null>(null);

  const openDocsSearch = useCallback(() => setSearchOpen(true), []);

  const registerDocsNavigate = useCallback((fn: ((pageId: string, tabId?: string) => void) | null) => {
    docsNavigateRef.current = fn;
  }, []);

  const navigateDocs = useCallback(
    (pageId: string, tabId?: string) => {
      if (docsNavigateRef.current) {
        docsNavigateRef.current(pageId, tabId);
        return;
      }
      const params = new URLSearchParams({ page: pageId });
      if (tabId) params.set("tab", tabId);
      router.push(`/docs?${params.toString()}`);
    },
    [router],
  );

  return (
    <DocsUIContext.Provider
      value={{
        isDocsPage,
        setIsDocsPage,
        mobileMenuOpen,
        setMobileMenuOpen,
        searchOpen,
        setSearchOpen,
        openDocsSearch,
        registerDocsNavigate,
        navigateDocs,
      }}
    >
      {children}
    </DocsUIContext.Provider>
  );
}

export function useDocsUI() {
  const ctx = useContext(DocsUIContext);
  if (!ctx) {
    throw new Error("useDocsUI must be used within a DocsUIProvider");
  }
  return ctx;
}
