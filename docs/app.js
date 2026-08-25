/**
 * Pala Landing Page Application Script
 * Features:
 * - Smart client-side OS detection
 * - Dynamic primary CTA button updating
 * - Live GitHub API release version fetch
 * - Interactive installation tab switcher
 * - One-click code snippet copy
 */

(function () {
  'use strict';

  // 1. Detect User Platform
  function detectPlatform() {
    const ua = navigator.userAgent;
    const platform = navigator.userAgentData?.platform || navigator.platform || '';

    if (/android/i.test(ua)) return 'android';
    if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'ios';
    if (/Win/i.test(platform) || /Windows/i.test(ua)) return 'windows';
    if (/Mac/i.test(platform) || /Macintosh/i.test(ua)) return 'macos';
    if (/Linux/i.test(platform) || /Linux/i.test(ua)) return 'linux';
    return 'unknown';
  }

  // 2. Download configurations
  const DOWNLOAD_MAP = {
    windows: {
      name: 'Windows',
      ctaText: 'Letöltés Windowsra (.exe)',
      badgeText: 'Asztali alkalmazás (64-bit)',
      url: 'https://github.com/CsPS0/pala/releases/latest',
      tabId: 'tab-desktop'
    },
    android: {
      name: 'Android',
      ctaText: 'Letöltés Androidra (.apk)',
      badgeText: 'Közvetlen APK telepítés',
      url: 'https://github.com/CsPS0/pala/releases/latest',
      tabId: 'tab-mobile'
    },
    ios: {
      name: 'iOS',
      ctaText: 'Megnyitás iOS-re (TestFlight / Web)',
      badgeText: 'iPhone és iPad kompatibilis',
      url: 'https://github.com/CsPS0/pala/releases/latest',
      tabId: 'tab-mobile'
    },
    macos: {
      name: 'macOS',
      ctaText: 'Letöltés macOS-re',
      badgeText: 'Apple Silicon & Intel',
      url: 'https://github.com/CsPS0/pala/releases/latest',
      tabId: 'tab-desktop'
    },
    linux: {
      name: 'Linux',
      ctaText: 'Letöltés Linuxra',
      badgeText: 'APT, AUR & Bináris',
      url: 'https://github.com/CsPS0/pala/releases/latest',
      tabId: 'tab-cli'
    },
    unknown: {
      name: 'Minden platform',
      ctaText: 'Kiadások és Letöltések',
      badgeText: 'Válassz platformot',
      url: 'https://github.com/CsPS0/pala/releases/latest',
      tabId: 'tab-desktop'
    }
  };

  // 3. Initialize Smart CTA
  function initSmartCTA() {
    const userOs = detectPlatform();
    const config = DOWNLOAD_MAP[userOs] || DOWNLOAD_MAP.unknown;

    const mainBtn = document.getElementById('main-download-btn');
    const badge = document.getElementById('detected-os-badge');

    if (mainBtn) {
      mainBtn.textContent = config.ctaText;
      mainBtn.href = config.url;
    }

    if (badge) {
      badge.textContent = 'Felismerve: ' + config.name + ' (' + config.badgeText + ')';
    }

    // Highlight chip in platform selector
    const chips = document.querySelectorAll('.platform-chip');
    chips.forEach(chip => {
      if (chip.getAttribute('data-platform') === userOs) {
        chip.classList.add('active');
      }
    });

    // Auto-select matching install tab
    if (config.tabId) {
      switchTab(config.tabId);
    }
  }

  // 4. Fetch Latest GitHub Release Version
  async function fetchLatestRelease() {
    const versionEl = document.getElementById('latest-version-tag');
    const releaseDateEl = document.getElementById('latest-release-date');

    try {
      const res = await fetch('https://api.github.com/repos/CsPS0/pala/releases/latest');
      if (res.ok) {
        const data = await res.json();
        if (data.tag_name && versionEl) {
          versionEl.textContent = data.tag_name;
        }
        if (data.published_at && releaseDateEl) {
          const date = new Date(data.published_at);
          releaseDateEl.textContent = 'Kiadva: ' + date.toLocaleDateString('hu-HU');
        }

        // Direct Windows / APK assets if available
        if (data.assets && Array.isArray(data.assets)) {
          const winAsset = data.assets.find(a => a.name.endsWith('.exe') || a.name.endsWith('.msi') || a.name.includes('windows'));
          const apkAsset = data.assets.find(a => a.name.endsWith('.apk'));

          if (winAsset) DOWNLOAD_MAP.windows.url = winAsset.browser_download_url;
          if (apkAsset) DOWNLOAD_MAP.android.url = apkAsset.browser_download_url;

          // Re-apply URL to button
          const userOs = detectPlatform();
          const mainBtn = document.getElementById('main-download-btn');
          if (mainBtn && DOWNLOAD_MAP[userOs]) {
            mainBtn.href = DOWNLOAD_MAP[userOs].url;
          }
        }
      }
    } catch (e) {
      console.warn('Could not fetch latest release info:', e);
    }
  }

  // 5. Install Tabs Management
  function switchTab(tabId) {
    const tabs = document.querySelectorAll('.install-tab');
    const panels = document.querySelectorAll('.install-panel');

    tabs.forEach(t => {
      if (t.getAttribute('data-tab') === tabId) {
        t.classList.add('active');
      } else {
        t.classList.remove('active');
      }
    });

    panels.forEach(p => {
      if (p.id === tabId) {
        p.classList.add('active');
      } else {
        p.classList.remove('active');
      }
    });
  }

  // 6. Copy Code Button Handler
  function initCopyButtons() {
    document.querySelectorAll('.copy-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const targetId = btn.getAttribute('data-copy-target');
        const codeEl = document.getElementById(targetId);
        if (codeEl) {
          const text = codeEl.textContent.trim();
          navigator.clipboard.writeText(text).then(() => {
            const original = btn.textContent;
            btn.textContent = 'Másolva!';
            setTimeout(() => {
              btn.textContent = original;
            }, 2000);
          });
        }
      });
    });
  }

  // 7. Event Listeners Init
  document.addEventListener('DOMContentLoaded', () => {
    initSmartCTA();
    fetchLatestRelease();
    initCopyButtons();

    // Tab buttons listener
    document.querySelectorAll('.install-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        const tabId = tab.getAttribute('data-tab');
        switchTab(tabId);
      });
    });
  });
})();
