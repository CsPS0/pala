import React from "react";

export function Wave() {
  return (
    <div className="flex justify-center w-full max-w-4xl mx-auto py-6 opacity-30 text-[#ff8800]" aria-hidden="true">
      <svg viewBox="0 0 400 24" preserveAspectRatio="none" className="w-full max-w-[360px] h-[18px]">
        <path
          d="M0 12 C 25 2, 75 2, 100 12 S 175 22, 200 12 S 275 2, 300 12 S 375 22, 400 12"
          fill="none"
          stroke="currentColor"
          strokeWidth="3"
          strokeLinecap="round"
        />
      </svg>
    </div>
  );
}
