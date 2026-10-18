"use client";

import React, { useState } from "react";
import { Copy, Check, Terminal } from "lucide-react";

interface CodeBlockProps {
  code: string;
  language?: string;
  title?: string;
}

export function CodeBlock({ code, language = "bash", title }: CodeBlockProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(code);
      } else {
        const textarea = document.createElement("textarea");
        textarea.value = code;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand("copy");
        document.body.removeChild(textarea);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.warn("Clipboard copy failed:", err);
    }
  };

  return (
    <div className="bg-bg border border-border rounded-2xl overflow-hidden my-3">
      <div className="px-3.5 py-2 bg-bg border-b border-border flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <Terminal size={13} className="text-primary shrink-0" />
          <span className="text-[11px] font-mono font-semibold text-muted truncate">
            {title || language}
          </span>
        </div>
        <button
          type="button"
          onClick={handleCopy}
          aria-label="Kód másolása a vágólapra"
          className="inline-flex items-center gap-1.5 text-[11px] font-mono font-bold px-2.5 py-1 rounded-lg bg-card hover:bg-card-hover border border-border hover:border-primary/50 text-fg hover:text-fg transition-all cursor-pointer shrink-0"
        >
          {copied ? (
            <>
              <Check size={12} className="text-primary" />
              <span className="text-primary">Másolva</span>
            </>
          ) : (
            <>
              <Copy size={12} />
              <span>Másolás</span>
            </>
          )}
        </button>
      </div>
      <pre className="p-3.5 sm:p-4 font-mono text-xs text-fg overflow-x-auto leading-relaxed">
        <code>{code}</code>
      </pre>
    </div>
  );
}
