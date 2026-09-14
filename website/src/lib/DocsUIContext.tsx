"use client";

import { createContext, useCallback, useContext, useRef, useState, type ReactNode } from "react";

interface DocsUIContextValue {
  isDocsPage: boolean;
  setIsDocsPage: (value: boolean) => void;
  mobileMenuOpen: boolean;
  setMobileMenuOpen: (value: boolean) => void;
  openDocsSearch: () => void;
  registerSearchOpener: (fn: (() => void) | null) => void;
}

const DocsUIContext = createContext<DocsUIContextValue | null>(null);

export function DocsUIProvider({ children }: { children: ReactNode }) {
  const [isDocsPage, setIsDocsPage] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const searchOpenerRef = useRef<(() => void) | null>(null);

  const openDocsSearch = useCallback(() => {
    searchOpenerRef.current?.();
  }, []);

  const registerSearchOpener = useCallback((fn: (() => void) | null) => {
    searchOpenerRef.current = fn;
  }, []);

  return (
    <DocsUIContext.Provider
      value={{ isDocsPage, setIsDocsPage, mobileMenuOpen, setMobileMenuOpen, openDocsSearch, registerSearchOpener }}
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
