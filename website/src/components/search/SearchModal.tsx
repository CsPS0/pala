"use client";

import React, { useEffect, useRef, useState } from "react";
import { CornerDownLeft, Search } from "lucide-react";
import { useDocsUI } from "@/lib/DocsUIContext";
import { SEARCH_INDEX } from "@/content/docs/searchIndex";

/** Site-wide docs search, opened with Ctrl/Cmd+K or the navbar search button on every page. */
export function SearchModal() {
  const { searchOpen, setSearchOpen, navigateDocs } = useDocsUI();
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedIndex, setSelectedIndex] = useState(0);
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Global shortcut. preventDefault stops the browser's own Ctrl+K (address/search bar).
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setSearchOpen(!searchOpen);
      } else if (e.key === "Escape" && searchOpen) {
        setSearchOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [searchOpen, setSearchOpen]);

  // Reset, focus the input and lock page scroll while open; give focus back to the opener on close.
  useEffect(() => {
    if (!searchOpen) return;
    const opener = document.activeElement as HTMLElement | null;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setSearchQuery("");
    setSelectedIndex(0);
    document.body.style.overflow = "hidden";
    const focusTimer = setTimeout(() => searchInputRef.current?.focus(), 50);
    return () => {
      clearTimeout(focusTimer);
      document.body.style.overflow = "";
      opener?.focus();
    };
  }, [searchOpen]);

  if (!searchOpen) return null;

  const q = searchQuery.trim().toLowerCase();
  const filteredResults = q === ""
    ? []
    : SEARCH_INDEX.filter((item) =>
        item.title.toLowerCase().includes(q) ||
        item.description.toLowerCase().includes(q) ||
        item.category.toLowerCase().includes(q) ||
        item.keywords.some((kw) => kw.toLowerCase().includes(q))
      );

  const select = (pageId: string, tabId?: string) => {
    setSearchOpen(false);
    navigateDocs(pageId, tabId);
  };

  const handleModalKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown" && filteredResults.length > 0) {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % filteredResults.length);
    } else if (e.key === "ArrowUp" && filteredResults.length > 0) {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + filteredResults.length) % filteredResults.length);
    } else if (e.key === "Enter" && filteredResults[selectedIndex]) {
      e.preventDefault();
      const item = filteredResults[selectedIndex];
      select(item.pageId, item.tabId);
    } else if (e.key === "Tab") {
      // Keep keyboard focus inside the modal dialog.
      const items = [...e.currentTarget.querySelectorAll<HTMLElement>("input, button")].filter(
        (el) => el.getClientRects().length > 0, // skip display:none (e.g. the sm:hidden close button)
      );
      const first = items[0];
      const last = items[items.length - 1];
      if (e.shiftKey ? document.activeElement === first : document.activeElement === last) {
        e.preventDefault();
        (e.shiftKey ? last : first).focus();
      }
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Dokumentáció kereső"
      className="fixed inset-0 z-[60] bg-bg/80 flex items-start justify-center p-3 sm:p-6 pt-6 sm:pt-24"
      onClick={() => setSearchOpen(false)}
    >
      <div
        className="w-full max-w-2xl bg-sidebar border border-border rounded-2xl overflow-hidden flex flex-col max-h-[80vh]"
        onClick={(e) => e.stopPropagation()}
        onKeyDown={handleModalKeyDown}
      >
        <div className="p-4 border-b border-border flex items-center gap-3 bg-bg">
          <Search size={18} className="text-primary shrink-0" />
          <input
            ref={searchInputRef}
            type="text"
            aria-label="Keresés a dokumentációban"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setSelectedIndex(0);
            }}
            placeholder="Keresés témák, parancsok, GYIK kérdések között..."
            className="flex-1 bg-transparent text-sm text-fg placeholder-subtle outline-none font-medium"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="text-xs text-muted hover:text-fg bg-card px-2 py-1 rounded"
            >
              Törlés
            </button>
          )}
          <kbd className="hidden sm:inline-block bg-card border border-border text-[10px] font-mono text-muted px-2 py-1 rounded">
            ESC
          </kbd>
        </div>

        <div className="p-2 overflow-y-auto divide-y divide-border/50 space-y-1 min-h-[140px] flex flex-col justify-center">
          {q === "" ? (
            <div className="p-8 text-center space-y-2">
              <div className="w-10 h-10 rounded-2xl bg-card border border-border text-muted flex items-center justify-center mx-auto mb-2">
                <Search size={18} />
              </div>
              <p className="text-xs font-semibold text-fg">Gépelj be egy kifejezést a kereséshez</p>
              <p className="text-[11px] text-subtle">
                Kereshetsz operációs rendszerre (pl. <code className="text-primary">windows</code>, <code className="text-primary">android</code>, <code className="text-primary">linux</code>), parancsokra (<code className="text-primary">--demo</code>), vagy adatvédelemre (<code className="text-primary">gdpr</code>).
              </p>
            </div>
          ) : filteredResults.length > 0 ? (
            filteredResults.map((item, idx) => {
              const isSelected = idx === selectedIndex;
              return (
                <button
                  key={item.id}
                  onClick={() => select(item.pageId, item.tabId)}
                  onMouseEnter={() => setSelectedIndex(idx)}
                  className={`w-full text-left p-3.5 rounded-xl transition-colors flex items-center justify-between group ${
                    isSelected ? "bg-primary/15 border border-primary/40" : "hover:bg-card border border-transparent"
                  }`}
                >
                  <div className="space-y-1 pr-4">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-bold text-primary uppercase tracking-wider bg-primary/10 px-1.5 py-0.5 rounded">
                        {item.category}
                      </span>
                      <h4 className="text-xs font-bold text-fg group-hover:text-primary transition-colors">
                        {item.title}
                      </h4>
                    </div>
                    <p className="text-[11px] text-muted line-clamp-1">{item.description}</p>
                  </div>
                  <div className="shrink-0 flex items-center text-muted group-hover:text-primary">
                    <CornerDownLeft size={14} className={isSelected ? "text-primary" : "opacity-0 group-hover:opacity-100"} />
                  </div>
                </button>
              );
            })
          ) : (
            <div className="p-8 text-center space-y-2">
              <p className="text-xs text-muted">Nincs találat a következőre: <strong className="text-fg">„{searchQuery}”</strong></p>
              <p className="text-[11px] text-subtle">Próbálj más kulcsszót keresni (pl. <code className="text-primary">windows</code>, <code className="text-primary">jegyek</code>, <code className="text-primary">gdpr</code>, <code className="text-primary">config</code>)</p>
            </div>
          )}
        </div>

        <div className="p-3 border-t border-border bg-bg text-[11px] font-mono text-muted flex items-center justify-between">
          <div className="hidden sm:flex items-center gap-3">
            <span><kbd className="bg-card px-1.5 py-0.5 rounded text-fg">↑↓</kbd> Navigáció</span>
            <span><kbd className="bg-card px-1.5 py-0.5 rounded text-fg">↵</kbd> Megnyitás</span>
            <span><kbd className="bg-card px-1.5 py-0.5 rounded text-fg">ESC</kbd> Bezárás</span>
          </div>
          <span className="text-subtle text-[10px] sm:text-[11px]">Pala Kereső</span>
          <button
            onClick={() => setSearchOpen(false)}
            className="sm:hidden text-xs text-primary font-bold px-2 py-1 bg-card rounded"
          >
            Bezárás
          </button>
        </div>
      </div>
    </div>
  );
}
