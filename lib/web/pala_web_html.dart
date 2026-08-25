import 'dart:convert';

class PalaWebHtml {
  static String render({
    required String studentName,
    required String institutionName,
    required String sessionToken,
    required int port,
    bool isAuthenticated = true,
    bool isDemo = false,
  }) {
    final safeStudent = htmlEscape.convert(studentName);
    final safeInst = htmlEscape.convert(institutionName);
    final safeToken = htmlEscape.convert(sessionToken);

    return '''<!DOCTYPE html>
<html lang="hu">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pala // Kréta Webes Felület</title>
  <style>
    :root {
      --bg: #0e0e11;
      --sidebar: #151518;
      --card: #1b1b1f;
      --card-hover: #222227;
      --card-alt: #18181c;
      --border: #28282d;
      --border-focus: #ff8800;
      --primary: #ff8800;
      --primary-hover: #ffa033;
      --primary-rgb: 255, 136, 0;
      --text: #f3f3f6;
      --text-muted: #8c8c94;
      --text-subtle: #5f5f67;
      --success: #30d158;
      --warning: #ffd60a;
      --danger: #ff453a;
      --info: #0a84ff;
      --purple: #bf5af2;
      --radius: 10px;
      --radius-sm: 6px;
      --transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }
    body {
      background-color: var(--bg);
      color: var(--text);
      display: flex;
      height: 100vh;
      overflow: hidden;
    }

    /* Scrollbars */
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
    ::-webkit-scrollbar-thumb:hover { background: var(--text-subtle); }

    /* SVG Icon styles */
    .icon {
      width: 18px;
      height: 18px;
      stroke-width: 2;
      stroke: currentColor;
      fill: none;
      stroke-linecap: round;
      stroke-linejoin: round;
      flex-shrink: 0;
    }
    .icon-sm { width: 14px; height: 14px; }
    .icon-lg { width: 22px; height: 22px; }

    /* Sidebar */
    .sidebar {
      width: 270px;
      background-color: var(--sidebar);
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      flex-shrink: 0;
      z-index: 10;
    }
    .logo-container {
      padding: 22px 20px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .logo-badge {
      background: linear-gradient(135deg, var(--primary) 0%, #ff6600 100%);
      color: #000;
      font-weight: 900;
      font-size: 0.9rem;
      padding: 5px 9px;
      border-radius: 6px;
      letter-spacing: 1px;
      box-shadow: 0 4px 12px rgba(var(--primary-rgb), 0.25);
      transition: var(--transition);
    }
    .logo-title {
      font-size: 1.15rem;
      font-weight: 700;
      color: #fff;
      letter-spacing: 0.3px;
    }
    .nav-links {
      list-style: none;
      padding: 16px 12px;
      flex-grow: 1;
      overflow-y: auto;
    }
    .nav-item {
      display: flex;
      align-items: center;
      gap: 14px;
      padding: 12px 14px;
      margin-bottom: 4px;
      border-radius: var(--radius-sm);
      color: var(--text-muted);
      cursor: pointer;
      font-size: 0.92rem;
      font-weight: 500;
      transition: var(--transition);
      user-select: none;
    }
    .nav-item:hover {
      background-color: var(--card-hover);
      color: var(--text);
    }
    .nav-item.active {
      background-color: rgba(var(--primary-rgb), 0.12);
      color: var(--primary);
      font-weight: 600;
      border-left: 3px solid var(--primary);
    }
    .user-profile {
      padding: 16px 20px;
      border-top: 1px solid var(--border);
      background-color: rgba(0, 0, 0, 0.25);
      cursor: pointer;
      transition: var(--transition);
    }
    .user-profile:hover {
      background-color: var(--card-hover);
    }
    .user-name {
      font-weight: 600;
      font-size: 0.92rem;
      color: #fff;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .user-inst {
      font-size: 0.78rem;
      color: var(--text-muted);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      margin-top: 3px;
    }

    /* Main Area */
    .main-content {
      flex-grow: 1;
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
      min-width: 0;
    }
    .top-bar {
      height: 64px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 28px;
      background-color: var(--sidebar);
      flex-shrink: 0;
    }
    .page-title {
      font-size: 1.25rem;
      font-weight: 700;
      color: #fff;
    }
    .top-actions {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .btn {
      padding: 8px 16px;
      border-radius: var(--radius-sm);
      font-size: 0.85rem;
      font-weight: 600;
      border: 1px solid var(--border);
      background-color: var(--card);
      color: var(--text);
      cursor: pointer;
      transition: var(--transition);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      white-space: nowrap;
    }
    .btn:hover {
      background-color: var(--card-hover);
      border-color: var(--text-subtle);
    }
    .btn-primary {
      background: linear-gradient(135deg, var(--primary) 0%, #ff6600 100%);
      color: #000;
      border-color: transparent;
      box-shadow: 0 2px 8px rgba(var(--primary-rgb), 0.2);
    }
    .btn-primary:hover {
      background: linear-gradient(135deg, var(--primary-hover) 0%, #ff7700 100%);
      box-shadow: 0 4px 14px rgba(var(--primary-rgb), 0.35);
    }
    .btn-danger {
      background-color: rgba(255, 69, 58, 0.15);
      color: var(--danger);
      border-color: rgba(255, 69, 58, 0.3);
    }
    .btn-danger:hover {
      background-color: rgba(255, 69, 58, 0.25);
    }

    /* Tab Content Wrapper */
    .content-body {
      flex-grow: 1;
      overflow-y: auto;
      padding: 24px 28px;
      min-width: 0;
    }
    .tab-pane {
      display: none;
    }
    .tab-pane.active {
      display: block;
      animation: fadeIn 0.2s ease-in-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(4px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* Cards & Grids */
    .grid-cards {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .card {
      background-color: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 20px;
      transition: var(--transition);
      min-width: 0;
      overflow: hidden;
    }
    .card:hover {
      border-color: rgba(var(--primary-rgb), 0.3);
    }
    .card-title {
      font-size: 0.78rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-muted);
      margin-bottom: 8px;
    }
    .card-value {
      font-size: 1.85rem;
      font-weight: 700;
      color: #fff;
    }
    .card-subtext {
      font-size: 0.8rem;
      color: var(--text-muted);
      margin-top: 6px;
    }

    /* Profile Details Grid & Overflow Protection */
    .info-list {
      display: flex;
      flex-direction: column;
      gap: 14px;
      width: 100%;
      min-width: 0;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 14px;
      padding-bottom: 12px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      font-size: 0.9rem;
      width: 100%;
      min-width: 0;
    }
    .info-row:last-child {
      border-bottom: none;
      padding-bottom: 0;
    }
    .info-label {
      color: var(--text-muted);
      font-size: 0.85rem;
      flex-shrink: 0;
      min-width: 90px;
      max-width: 140px;
    }
    .info-val {
      color: #fff;
      font-weight: 600;
      text-align: right;
      word-break: break-word;
      overflow-wrap: anywhere;
      min-width: 0;
      flex-grow: 1;
    }

    /* Live Countdown Widget */
    .live-banner {
      background: linear-gradient(135deg, rgba(var(--primary-rgb), 0.12) 0%, rgba(var(--primary-rgb), 0.03) 100%);
      border: 1px solid rgba(var(--primary-rgb), 0.25);
      border-radius: var(--radius);
      padding: 20px 24px;
      margin-bottom: 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }
    .live-text-main {
      font-size: 1.15rem;
      font-weight: 700;
      color: var(--primary);
    }
    .live-text-sub {
      font-size: 0.85rem;
      color: var(--text-muted);
      margin-top: 4px;
    }
    .progress-bar-bg {
      background-color: rgba(255, 255, 255, 0.08);
      border-radius: 4px;
      height: 6px;
      overflow: hidden;
      margin-top: 10px;
      width: 100%;
    }
    .progress-bar-fill {
      height: 100%;
      background: linear-gradient(90deg, var(--primary) 0%, #ffaa33 100%);
      transition: width 0.3s ease;
    }

    /* Tables */
    .table-container {
      background-color: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      overflow-x: auto;
      margin-bottom: 24px;
      max-width: 100%;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }
    th {
      background-color: rgba(0, 0, 0, 0.3);
      padding: 13px 16px;
      font-size: 0.78rem;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }
    td {
      padding: 13px 16px;
      font-size: 0.9rem;
      border-bottom: 1px solid var(--border);
    }
    tr:last-child td {
      border-bottom: none;
    }
    tr:hover td {
      background-color: rgba(255, 255, 255, 0.02);
    }

    /* Grade Badges */
    .grade-badge {
      display: inline-block;
      width: 28px;
      height: 28px;
      line-height: 28px;
      text-align: center;
      border-radius: 6px;
      font-weight: 700;
      font-size: 0.95rem;
    }
    .grade-5 { background-color: rgba(48, 209, 88, 0.2); color: var(--success); }
    .grade-4 { background-color: rgba(255, 136, 0, 0.2); color: var(--primary); }
    .grade-3 { background-color: rgba(255, 214, 10, 0.2); color: var(--warning); }
    .grade-2 { background-color: rgba(255, 149, 0, 0.2); color: #ff9500; }
    .grade-1 { background-color: rgba(255, 69, 58, 0.2); color: var(--danger); }

    /* Timetable Grid */
    .timetable-grid {
      display: grid;
      grid-template-columns: 60px repeat(5, 1fr);
      gap: 10px;
      margin-top: 16px;
      overflow-x: auto;
    }
    .tt-header {
      background-color: var(--sidebar);
      padding: 12px;
      text-align: center;
      font-weight: 600;
      font-size: 0.85rem;
      border-radius: var(--radius-sm);
      border: 1px solid var(--border);
      color: #fff;
    }
    .tt-period-num {
      background-color: rgba(0, 0, 0, 0.3);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 0.9rem;
      color: var(--text-muted);
      border-radius: var(--radius-sm);
      border: 1px solid var(--border);
    }
    .tt-cell {
      background-color: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      padding: 10px 12px;
      min-height: 74px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      transition: var(--transition);
      overflow: hidden;
    }
    .tt-cell:hover {
      border-color: rgba(var(--primary-rgb), 0.4);
      background-color: var(--card-hover);
    }
    .tt-subject {
      font-weight: 600;
      font-size: 0.88rem;
      color: #fff;
      word-break: break-word;
    }
    .tt-room {
      font-size: 0.75rem;
      color: var(--text-muted);
      margin-top: 4px;
    }
    .tt-cancelled {
      border-color: var(--danger);
      background-color: rgba(255, 69, 58, 0.08);
      text-decoration: line-through;
    }

    /* Modal */
    .modal-overlay {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background-color: rgba(0, 0, 0, 0.78);
      z-index: 1000;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(4px);
    }
    .modal-overlay.open {
      display: flex;
      animation: fadeIn 0.15s ease-out;
    }
    .modal {
      background-color: var(--sidebar);
      border: 1px solid var(--border);
      border-radius: 12px;
      width: 90%;
      max-width: 650px;
      max-height: 85vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      box-shadow: 0 16px 36px rgba(0,0,0,0.6);
    }
    .modal-header {
      padding: 18px 24px;
      border-bottom: 1px solid var(--border);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .modal-body {
      padding: 24px;
      overflow-y: auto;
      flex-grow: 1;
    }
    .modal-footer {
      padding: 16px 24px;
      border-top: 1px solid var(--border);
      display: flex;
      justify-content: flex-end;
      gap: 12px;
    }
    .form-group {
      margin-bottom: 16px;
    }
    .form-group label {
      display: block;
      font-size: 0.82rem;
      font-weight: 600;
      color: var(--text-muted);
      margin-bottom: 6px;
    }
    .form-control {
      width: 100%;
      padding: 10px 14px;
      background-color: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      color: var(--text);
      font-size: 0.9rem;
      transition: var(--transition);
    }
    .form-control:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 2px rgba(var(--primary-rgb), 0.2);
    }
    textarea.form-control {
      resize: vertical;
      min-height: 120px;
    }

    /* Status indicator - Never wrap */
    .status-pill {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 4px 10px;
      border-radius: 4px;
      font-size: 0.78rem;
      font-weight: 600;
      white-space: nowrap;
      line-height: 1.2;
      text-align: center;
    }
    .pill-green { background-color: rgba(48, 209, 88, 0.2); color: var(--success); }
    .pill-yellow { background-color: rgba(255, 214, 10, 0.2); color: var(--warning); }
    .pill-red { background-color: rgba(255, 69, 58, 0.2); color: var(--danger); }
    .pill-orange { background-color: rgba(var(--primary-rgb), 0.2); color: var(--primary); }
    .pill-gray { background-color: rgba(255, 255, 255, 0.1); color: var(--text-muted); }

    /* Theme color picker pills */
    .color-swatch-group {
      display: flex;
      gap: 12px;
      margin-top: 8px;
    }
    .color-swatch {
      width: 34px;
      height: 34px;
      border-radius: 50%;
      cursor: pointer;
      border: 2px solid transparent;
      transition: var(--transition);
      position: relative;
    }
    .color-swatch:hover {
      transform: scale(1.1);
    }
    .color-swatch.active {
      border-color: #fff;
      box-shadow: 0 0 10px currentColor;
    }

    /* TUI Settings lock overlay */
    .tui-locked-wrapper {
      position: relative;
    }
    .tui-locked {
      opacity: 0.45;
      pointer-events: none;
      user-select: none;
      filter: grayscale(0.6);
      transition: var(--transition);
    }
    .lock-banner {
      background: linear-gradient(135deg, rgba(255, 214, 10, 0.12) 0%, rgba(255, 214, 10, 0.03) 100%);
      border: 1px solid rgba(255, 214, 10, 0.28);
      border-radius: var(--radius);
      padding: 16px 20px;
      margin-bottom: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
    }

    /* Homework Checklist Checkbox */
    .hw-checkbox {
      width: 18px;
      height: 18px;
      cursor: pointer;
      accent-color: var(--primary);
    }
    .hw-done {
      text-decoration: line-through;
      opacity: 0.5;
    }

    /* Grade Distribution Chart */
    .grade-chart-bar-container {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 8px;
    }
    .grade-chart-label {
      width: 24px;
      font-weight: 700;
      font-size: 0.9rem;
    }
    .grade-chart-track {
      flex-grow: 1;
      height: 14px;
      background-color: rgba(255, 255, 255, 0.06);
      border-radius: 7px;
      overflow: hidden;
    }
    .grade-chart-bar {
      height: 100%;
      border-radius: 7px;
      transition: width 0.4s ease;
    }
    .grade-chart-count {
      width: 70px;
      text-align: right;
      font-size: 0.8rem;
      color: var(--text-muted);
    }

    /* Toast */
    .toast {
      position: fixed;
      bottom: 24px;
      right: 24px;
      background-color: var(--card);
      border: 1px solid var(--border);
      padding: 12px 20px;
      border-radius: var(--radius-sm);
      font-size: 0.9rem;
      font-weight: 600;
      display: none;
      z-index: 2000;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
    }
    .toast.show { display: block; animation: fadeIn 0.2s ease-out; }
    .toast.success { border-color: var(--success); color: var(--success); }
    .toast.error { border-color: var(--danger); color: var(--danger); }
  </style>
</head>
<body>

  <!-- Sidebar -->
  <aside class="sidebar">
    <div class="logo-container">
      <div class="logo-badge">PALA</div>
      <div class="logo-title">Kréta Web</div>
    </div>
    <ul class="nav-links">
      <li class="nav-item active" onclick="switchTab('dashboard')">
        <svg class="icon" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
        <span>Vezérlőpult</span>
      </li>
      <li class="nav-item" onclick="switchTab('grades')">
        <svg class="icon" viewBox="0 0 24 24"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>
        <span>Érdemjegyek</span>
      </li>
      <li class="nav-item" onclick="switchTab('timetable')">
        <svg class="icon" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
        <span>Órarend</span>
      </li>
      <li class="nav-item" onclick="switchTab('homework')">
        <svg class="icon" viewBox="0 0 24 24"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
        <span>Házi feladatok & Dolgozatok</span>
      </li>
      <li class="nav-item" onclick="switchTab('messages')">
        <svg class="icon" viewBox="0 0 24 24"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
        <span>Üzenetek</span>
      </li>
      <li class="nav-item" onclick="switchTab('absences')">
        <svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        <span>Mulasztások & Igazolások</span>
      </li>
      <li class="nav-item" onclick="switchTab('stats')">
        <svg class="icon" viewBox="0 0 24 24"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        <span>Statisztika & Átlagok</span>
      </li>
      <li class="nav-item" onclick="switchTab('profile')">
        <svg class="icon" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
        <span>Tanulói Adatlap</span>
      </li>
      <li class="nav-item" onclick="switchTab('settings')">
        <svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        <span>Beállítások</span>
      </li>
    </ul>
    <div class="user-profile" onclick="switchTab('profile')" title="Kattints a részletes tanulói adatlap megnyitásához">
      <div class="user-name" id="profileName">$safeStudent</div>
      <div class="user-inst" id="profileInst">$safeInst</div>
    </div>
  </aside>

  <!-- Main Content -->
  <main class="main-content">
    <header class="top-bar">
      <div class="page-title" id="pageHeader">Vezérlőpult</div>
      <div class="top-actions">
        <button class="btn" onclick="openLoginModal()" id="btnAccountAction" title="Fiókváltás vagy bejelentkezés">
          <svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>
          <span id="accountActionText">Bejelentkezés</span>
        </button>
        <button class="btn" onclick="loadAllData()">
          <svg class="icon icon-sm" viewBox="0 0 24 24"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
          Frissítés
        </button>
        <button class="btn btn-primary" onclick="openComposerModal()">
          <svg class="icon icon-sm" viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Új üzenet tanárnak
        </button>
      </div>
    </header>

    <div class="content-body">

      <!-- TAB: DASHBOARD -->
      <section id="tab-dashboard" class="tab-pane active">
        <div id="liveCountdown" class="live-banner">
          <div style="flex-grow: 1; min-width: 0;">
            <div class="live-text-main" id="countdownTitle">Adatok betöltése...</div>
            <div class="live-text-sub" id="countdownSub">Csatlakozás a helyi szerverhez...</div>
            <div class="progress-bar-bg" id="lessonProgressWrap" style="display: none;">
              <div class="progress-bar-fill" id="lessonProgressFill" style="width: 0%;"></div>
            </div>
          </div>
        </div>

        <div class="grid-cards">
          <div class="card">
            <div class="card-title">Tanulmányi Átlag (GPA)</div>
            <div class="card-value" id="dashGpa">--</div>
            <div class="card-subtext" id="dashGpaSub">Összes tantárgy alapján</div>
          </div>
          <div class="card">
            <div class="card-title">Mai Órák</div>
            <div class="card-value" id="dashLessonsCount">--</div>
            <div class="card-subtext" id="dashLessonsSub">0 hátralévő óra</div>
          </div>
          <div class="card">
            <div class="card-title">Szülői Igazolás Keret</div>
            <div class="card-value" id="dashQuota">--</div>
            <div class="card-subtext" id="dashQuotaSub">nap felhasználva</div>
          </div>
          <div class="card">
            <div class="card-title">Közelgő Számonkérések</div>
            <div class="card-value" id="dashExamsCount">--</div>
            <div class="card-subtext" id="dashExamsSub">a következő napokban</div>
          </div>
        </div>

        <div class="card" style="margin-bottom: 24px;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
            <h3 style="font-size: 1rem; color: #fff;">Mai Órarend Részletesen</h3>
            <button class="btn" onclick="switchTab('timetable')">Teljes heti órarend &rarr;</button>
          </div>
          <div class="table-container" style="margin-bottom: 0;">
            <table id="dashTodayTable">
              <thead>
                <tr>
                  <th>Óra</th>
                  <th>Idősáv</th>
                  <th>Tantárgy</th>
                  <th>Terem</th>
                  <th>Tanár</th>
                  <th>Státusz</th>
                </tr>
              </thead>
              <tbody>
                <tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- TAB: GRADES -->
      <section id="tab-grades" class="tab-pane">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; gap: 12px; flex-wrap: wrap;">
          <input type="text" id="gradeSearch" class="form-control" placeholder="Keresés tantárgy vagy téma alapján..." style="max-width: 350px;" oninput="filterGrades()" />
          <div style="display: flex; gap: 8px;">
            <button class="btn" onclick="openGhostSimulator()">
              <svg class="icon icon-sm" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 8v8"/><path d="M8 12h8"/></svg>
              Szellem Jegy Szimulátor
            </button>
          </div>
        </div>

        <div class="table-container">
          <table id="gradesTable">
            <thead>
              <tr>
                <th>Jegy</th>
                <th>Tantárgy</th>
                <th>Típus / Téma</th>
                <th>Súly</th>
                <th>Dátum</th>
                <th>Tanár</th>
              </tr>
            </thead>
            <tbody>
              <tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- TAB: TIMETABLE -->
      <section id="tab-timetable" class="tab-pane">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 12px;">
          <div style="display: flex; gap: 8px; align-items: center;">
            <button class="btn" onclick="changeWeek(-1)">&lt; Előző hét</button>
            <button class="btn" onclick="changeWeek(0)">Aktuális hét</button>
            <button class="btn" onclick="changeWeek(1)">Következő hét &gt;</button>
          </div>
          <div id="timetableWeekLabel" style="font-weight: 600; color: var(--primary);">Betöltés...</div>
        </div>

        <div class="timetable-grid" id="timetableGrid">
          <!-- Populated by JS -->
        </div>
      </section>

      <!-- TAB: HOMEWORK & EXAMS -->
      <section id="tab-homework" class="tab-pane">
        <h3 style="margin-bottom: 16px; color: #fff;">Közelgő Dolgozatok és Számonkérések</h3>
        <div class="table-container">
          <table id="examsTable">
            <thead>
              <tr>
                <th>Dátum</th>
                <th>Tantárgy</th>
                <th>Mód / Típus</th>
                <th>Téma</th>
              </tr>
            </thead>
            <tbody>
              <tr><td colspan="4" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
            </tbody>
          </table>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; margin: 28px 0 16px 0; flex-wrap: wrap; gap: 8px;">
          <h3 style="color: #fff;">Házi Feladatok (Interaktív Teendőlista)</h3>
          <span style="font-size: 0.8rem; color: var(--text-muted);">A pipálás a böngésződben mentésre kerül</span>
        </div>
        <div class="table-container">
          <table id="homeworkTable">
            <thead>
              <tr>
                <th style="width: 40px;">Kész</th>
                <th>Határidő</th>
                <th>Tantárgy</th>
                <th>Feladat szövege</th>
                <th>Feladás dátuma</th>
              </tr>
            </thead>
            <tbody>
              <tr><td colspan="5" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- TAB: MESSAGES -->
      <section id="tab-messages" class="tab-pane">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
          <h3 style="color: #fff;">Beérkezett Üzenetek</h3>
          <button class="btn btn-primary" onclick="openComposerModal()">+ Új üzenet írása</button>
        </div>

        <div class="table-container">
          <table id="messagesTable">
            <thead>
              <tr>
                <th>Dátum</th>
                <th>Feladó</th>
                <th>Tárgy</th>
                <th>Művelet</th>
              </tr>
            </thead>
            <tbody>
              <tr><td colspan="4" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- TAB: ABSENCES & EXCUSES -->
      <section id="tab-absences" class="tab-pane">
        <div class="grid-cards">
          <div class="card">
            <div class="card-title">Összes Mulasztás</div>
            <div class="card-value" id="absTotalHours">-- óra</div>
            <div class="card-subtext">250 órás határ: <span id="absDangerPct">0%</span></div>
          </div>
          <div class="card">
            <div class="card-title">Szülői Keret Állás</div>
            <div class="card-value" id="absQuotaStatus">--</div>
            <div class="card-subtext" id="absQuotaSub">Iskolai házirend alapján</div>
          </div>
          <div class="card">
            <div class="card-title">Igazolandó Órák</div>
            <div class="card-value" id="absPendingCount">-- óra</div>
            <div class="card-subtext">Jelenleg igazolásra vár</div>
          </div>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
          <h3 style="color: #fff;">Mulasztások Listája</h3>
          <button class="btn btn-primary" onclick="openExcuseGenerator()">+ Szülői Igazolás Készítése</button>
        </div>

        <div class="table-container">
          <table id="absencesTable">
            <thead>
              <tr>
                <th>Dátum</th>
                <th>Tantárgy</th>
                <th>Típus</th>
                <th>Státusz</th>
                <th>Késés (perc)</th>
              </tr>
            </thead>
            <tbody>
              <tr><td colspan="5" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- TAB: STATS & AVERAGES -->
      <section id="tab-stats" class="tab-pane">
        <div class="grid-cards">
          <div class="card" style="grid-column: span 2;">
            <h3 style="font-size: 1rem; color: #fff; margin-bottom: 16px;">Jegyek Eloszlása</h3>
            <div id="gradeDistributionChart">
              <!-- Rendered by JS -->
            </div>
          </div>
          <div class="card">
            <h3 style="font-size: 1rem; color: #fff; margin-bottom: 16px;">Tanulmányi Összegzés</h3>
            <div style="font-size: 0.88rem; color: var(--text-muted); line-height: 1.8;">
              <div>Összes rögzített jegy: <strong id="statsTotalGrades" style="color: #fff;">--</strong></div>
              <div>Legjobb jegy arány (5-ös): <strong id="statsFivePct" style="color: var(--success);">--%</strong></div>
              <div>Bukási kockázat (1-es): <strong id="statsOneCount" style="color: var(--danger);">-- db</strong></div>
            </div>
          </div>
        </div>

        <h3 style="margin: 28px 0 16px 0; color: #fff;">Tantárgyi Átlagok Rangsorolva</h3>
        <div class="table-container">
          <table id="subjectAveragesTable">
            <thead>
              <tr>
                <th>Tantárgy</th>
                <th>Átlag</th>
                <th>Jegyek száma</th>
                <th>Állapot</th>
              </tr>
            </thead>
            <tbody>
              <tr><td colspan="4" style="text-align: center; color: var(--text-muted);">Betöltés...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- TAB: USER PROFILE / INFORMATIONS -->
      <section id="tab-profile" class="tab-pane">
        <div class="grid-cards">
          <div class="card" style="grid-column: span 2;">
            <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 16px;">Személyes Adatok</h3>
            <div class="info-list">
              <div class="info-row">
                <span class="info-label">Teljes név</span>
                <span class="info-val" id="profFullName">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Születési név</span>
                <span class="info-val" id="profBirthName">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Születési hely és idő</span>
                <span class="info-val" id="profBirthPlaceDate">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Anyja leánykori neve</span>
                <span class="info-val" id="profMothersName">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Oktatási azonosító (UID)</span>
                <span class="info-val"><span class="status-pill pill-orange" id="profUid">-</span></span>
              </div>
            </div>
          </div>

          <div class="card">
            <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 16px;">Elérhetőség & Cím</h3>
            <div class="info-list">
              <div class="info-row">
                <span class="info-label">Email</span>
                <span class="info-val" id="profEmail">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Telefonszám</span>
                <span class="info-val" id="profPhone">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Lakcím / Címek</span>
                <span class="info-val" id="profAddresses">-</span>
              </div>
            </div>
          </div>
        </div>

        <div class="grid-cards">
          <div class="card">
            <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 16px;">Oktatási Intézmény</h3>
            <div class="info-list">
              <div class="info-row">
                <span class="info-label">Intézmény neve</span>
                <span class="info-val" id="profInstName">-</span>
              </div>
              <div class="info-row">
                <span class="info-label">Karbantartás / Leállás</span>
                <span class="info-val" id="profDowntime" style="color: var(--warning);">-</span>
              </div>
            </div>
          </div>

          <div class="card" style="grid-column: span 2;">
            <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 16px;">Regisztrált Gondviselők</h3>
            <div id="profGuardiansList" class="info-list">
              <div style="color: var(--text-muted);">Nincsenek elérhető adatok.</div>
            </div>
          </div>
        </div>
      </section>

      <!-- TAB: SETTINGS -->
      <section id="tab-settings" class="tab-pane">
        
        <!-- SECTION 1: WEB SETTINGS (ACTIVE) -->
        <h2 style="font-size: 1.15rem; color: #fff; margin-bottom: 16px; display: flex; align-items: center; gap: 10px;">
          <svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
          Webes Felület Beállításai
          <span class="status-pill pill-green">AKTÍV</span>
        </h2>

        <div class="grid-cards">
          <!-- Web Theme & Color Palette -->
          <div class="card">
            <h3 style="font-size: 1rem; color: #fff; margin-bottom: 8px;">Kiemelő Színválasztó</h3>
            <p style="font-size: 0.83rem; color: var(--text-muted); margin-bottom: 14px;">
              Válassz a modern Pala színtémák közül a webes felülethez:
            </p>
            <div class="color-swatch-group">
              <div class="color-swatch active" style="background-color: #ff8800;" onclick="setWebAccentColor('orange', '#ff8800', '255, 136, 0')" title="Pala Narancs"></div>
              <div class="color-swatch" style="background-color: #0a84ff;" onclick="setWebAccentColor('blue', '#0a84ff', '10, 132, 255')" title="Kréta Kék"></div>
              <div class="color-swatch" style="background-color: #30d158;" onclick="setWebAccentColor('emerald', '#30d158', '48, 209, 88')" title="Smaragd Zöld"></div>
              <div class="color-swatch" style="background-color: #bf5af2;" onclick="setWebAccentColor('purple', '#bf5af2', '191, 90, 242')" title="Királyi Lila"></div>
            </div>
          </div>

          <!-- Account & Web Session -->
          <div class="card">
            <h3 style="font-size: 1rem; color: #fff; margin-bottom: 8px;">Fiók & Bejelentkezés</h3>
            <p style="font-size: 0.83rem; color: var(--text-muted); margin-bottom: 14px;">
              Aktív profil: <strong id="setProfileStatus" style="color: #fff;">$safeStudent</strong>
            </p>
            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
              <button class="btn btn-primary" onclick="openLoginModal()">Fiókváltás / Belépés</button>
              <button class="btn btn-danger" onclick="logoutSession()">Kijelentkezés</button>
            </div>
          </div>

          <!-- Web Cache & Storage -->
          <div class="card">
            <h3 style="font-size: 1rem; color: #fff; margin-bottom: 8px;">Böngészős Gyorsítótár</h3>
            <p style="font-size: 0.83rem; color: var(--text-muted); margin-bottom: 14px;">
              A kipipált házi feladatok és helyi beállítások ürítése:
            </p>
            <button class="btn" onclick="clearWebStorage()">Gyorsítótár ürítése</button>
          </div>
        </div>

        <hr style="border: none; border-top: 1px solid var(--border); margin: 32px 0 24px 0;" />

        <!-- SECTION 2: TUI SETTINGS (LOCKED BY DEFAULT) -->
        <div class="lock-banner">
          <div style="display: flex; align-items: center; gap: 12px; min-width: 0;">
            <svg class="icon icon-lg" style="color: var(--warning);" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
            <div>
              <div style="font-weight: 700; color: #fff; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                Terminális (TUI) Beállítások
                <span id="tuiLockBadge" class="status-pill pill-yellow">ZÁROLVA (Webes nézet)</span>
              </div>
              <div style="font-size: 0.82rem; color: var(--text-muted); margin-top: 2px;">
                A terminális konfiguráció zárolva van a webes felületen a párhuzamos felülírások elkerülése végett.
              </div>
            </div>
          </div>
          <button class="btn" id="btnToggleTuiLock" onclick="toggleTuiSettingsLock()">
            <svg class="icon icon-sm" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 9.9-1"/></svg>
            <span id="btnToggleTuiLockText">Zárolás feloldása</span>
          </button>
        </div>

        <div id="tuiSettingsContainer" class="tui-locked">
          <div class="grid-cards">
            <!-- Parental Quota Settings Card -->
            <div class="card">
              <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 16px;">Szülői Igazolás Keret</h3>
              <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 14px;">
                Állítsd be az intézményed házirendje szerinti éves szülői igazolási keretet (alapértelmezett: 5 nap).
              </p>
              <div class="form-group">
                <label for="setParentalQuotaInput">Keret (nap/tanév)</label>
                <input type="number" id="setParentalQuotaInput" class="form-control" min="1" max="30" value="5" />
              </div>
              <button class="btn btn-primary" onclick="saveParentalQuotaSetting()">Keret Mentése</button>
            </div>

            <!-- Terminal Appearance -->
            <div class="card">
              <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 16px;">Terminál Megjelenés</h3>
              <div class="form-group">
                <label>Terminál ASCII Fejléc</label>
                <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; color: var(--text); font-weight: normal; margin-top: 6px;">
                  <input type="checkbox" id="setShowAsciiBanner" class="hw-checkbox" onchange="saveGeneralSettings()" />
                  Nagy ASCII Pala logó megjelenítése a terminálban
                </label>
              </div>
            </div>
          </div>

          <!-- Subject Aliases Card -->
          <div class="card" style="margin-bottom: 24px;">
            <h3 style="font-size: 1.05rem; color: #fff; margin-bottom: 12px;">Tantárgy Átnevezések (Aliasok)</h3>
            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 16px;">
              Itt egyéni rövid neveket állíthatsz be a hosszú tantárgynevek helyett (pl. Matematika &rarr; Matek).
            </p>

            <div style="display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap;">
              <input type="text" id="newAliasOriginal" class="form-control" placeholder="Eredeti tantárgynév (pl. Matematika)" style="flex: 1; min-width: 200px;" />
              <input type="text" id="newAliasCustom" class="form-control" placeholder="Egyéni rövid név (pl. Matek)" style="flex: 1; min-width: 200px;" />
              <button class="btn btn-primary" onclick="addNewAlias()">Hozzáadás</button>
            </div>

            <div class="table-container" style="margin-bottom: 0;">
              <table id="aliasesTable">
                <thead>
                  <tr>
                    <th>Eredeti Tantárgynév</th>
                    <th>Megjelenített Név</th>
                    <th style="width: 100px;">Művelet</th>
                  </tr>
                </thead>
                <tbody>
                  <tr><td colspan="3" style="text-align: center; color: var(--text-muted);">Nincsenek egyéni átnevezések.</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

      </section>

    </div>
  </main>

  <!-- MODAL: Kréta Login / Switch Account -->
  <div id="loginModal" class="modal-overlay">
    <div class="modal" style="max-width: 520px;">
      <div class="modal-header">
        <h3 style="color: #fff;">Bejelentkezés Kréta Fiókba</h3>
        <button class="btn" onclick="closeLoginModal()">Bezárás</button>
      </div>
      <div class="modal-body">
        <div style="display: flex; gap: 8px; margin-bottom: 18px; border-bottom: 1px solid var(--border); padding-bottom: 12px;">
          <button class="btn btn-primary" id="btnTabRealLogin" onclick="switchLoginTab('real')" style="flex: 1;">Kréta Fiók Belépés</button>
          <button class="btn" id="btnTabDemoLogin" onclick="switchLoginTab('demo')" style="flex: 1;">Demó Mód (Teszt Elek)</button>
        </div>

        <!-- Real Account Form -->
        <div id="loginRealForm">
          <div class="form-group">
            <label for="loginSchoolSearch">Intézmény keresése vagy azonosító kódja</label>
            <input type="text" id="loginSchoolSearch" class="form-control" placeholder="pl. klébelsberg vagy klik123456" oninput="onSchoolSearchInput()" />
            <div id="schoolSuggestions" style="display: none; max-height: 140px; overflow-y: auto; background-color: var(--card); border: 1px solid var(--border); border-radius: var(--radius-sm); margin-top: 4px;"></div>
          </div>
          <div class="form-group">
            <label for="loginInstituteCode">Intézmény azonosító (Kréta kód)</label>
            <input type="text" id="loginInstituteCode" class="form-control" placeholder="pl. klik123456" />
          </div>
          <div class="form-group">
            <label for="loginUsername">Felhasználónév (Oktatási / Tanulói azonosító)</label>
            <input type="text" id="loginUsername" class="form-control" placeholder="7xxxxxxxxxx vagy felhasználónév" />
          </div>
          <div class="form-group">
            <label for="loginPassword">Jelszó</label>
            <input type="password" id="loginPassword" class="form-control" placeholder="••••••••" />
          </div>
          <div id="loginErrorMsg" style="display: none; color: var(--danger); font-size: 0.85rem; margin-bottom: 12px;"></div>
        </div>

        <!-- Demo Account Section -->
        <div id="loginDemoForm" style="display: none; text-align: center; padding: 16px 0;">
          <div style="font-size: 1.05rem; font-weight: 700; color: #fff; margin-bottom: 8px;">Teszt Elek Demó Profil</div>
          <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 20px;">
            Azonnali belépés valósághű generált tanévvel, 80+ érdemjeggyel, órarenddel és üzenetekkel jelszó nélkül.
          </p>
          <button class="btn btn-primary" style="width: 100%; padding: 12px;" onclick="submitDemoLogin()">Belépés Demó Fiókkal</button>
        </div>
      </div>
      <div class="modal-footer" id="loginRealFooter">
        <button class="btn" onclick="closeLoginModal()">Mégse</button>
        <button class="btn btn-primary" id="btnLoginSubmit" onclick="submitRealLogin()">Bejelentkezés</button>
      </div>
    </div>
  </div>

  <!-- MODAL: Composer -->
  <div id="composerModal" class="modal-overlay">
    <div class="modal">
      <div class="modal-header">
        <h3 style="color: #fff;" id="modalComposerTitle">Új üzenet küldése tanárnak</h3>
        <button class="btn" onclick="closeComposerModal()">Bezárás</button>
      </div>
      <div class="modal-body">
        <div class="form-group">
          <label for="compRecipient">Címzett tanár</label>
          <select id="compRecipient" class="form-control">
            <option value="">Tanárok betöltése...</option>
          </select>
        </div>
        <div class="form-group">
          <label for="compSubject">Üzenet tárgya</label>
          <input type="text" id="compSubject" class="form-control" placeholder="pl. Kérdés a dolgozattal kapcsolatban" />
        </div>
        <div class="form-group">
          <label for="compText">Üzenet szövege</label>
          <textarea id="compText" class="form-control" rows="6" placeholder="Tisztelt Tanár Úr / Tanárnő!..."></textarea>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn" onclick="closeComposerModal()">Mégse</button>
        <button class="btn btn-primary" onclick="sendMessageFromModal()">Üzenet elküldése</button>
      </div>
    </div>
  </div>

  <!-- MODAL: Message Viewer -->
  <div id="messageViewerModal" class="modal-overlay">
    <div class="modal">
      <div class="modal-header">
        <h3 style="color: #fff;" id="viewMsgSubject">Üzenet részletei</h3>
        <button class="btn" onclick="closeMsgViewer()">Bezárás</button>
      </div>
      <div class="modal-body">
        <div style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 16px;">
          <div>Feladó: <strong id="viewMsgSender" style="color: #fff;">-</strong></div>
          <div style="margin-top: 4px;">Dátum: <span id="viewMsgDate">-</span></div>
        </div>
        <div id="viewMsgBody" style="background-color: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 16px; white-space: pre-wrap; font-size: 0.92rem; line-height: 1.6; color: var(--text);">
          -
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn" onclick="closeMsgViewer()">Bezárás</button>
        <button class="btn btn-primary" id="btnReplyMsg">Válasz írása</button>
      </div>
    </div>
  </div>

  <!-- MODAL: Ghost Simulator -->
  <div id="ghostModal" class="modal-overlay">
    <div class="modal">
      <div class="modal-header">
        <h3 style="color: #fff;">Szellem Jegy Szimulátor</h3>
        <button class="btn" onclick="closeGhostSimulator()">Bezárás</button>
      </div>
      <div class="modal-body">
        <p style="font-size: 0.88rem; color: var(--text-muted); margin-bottom: 16px;">
          Próbáld ki, hogyan változna a tantárgyi átlagod és az összesített GPA-d, ha kapnál egy bizonyos jegyet!
        </p>
        <div class="form-group">
          <label for="ghostSubjectSelect">Válassz tantárgyat</label>
          <select id="ghostSubjectSelect" class="form-control" onchange="recalculateGhostSimulation()">
            <!-- Populated by JS -->
          </select>
        </div>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
          <div class="form-group">
            <label for="ghostGradeValue">Szimulált érdemjegy</label>
            <select id="ghostGradeValue" class="form-control" onchange="recalculateGhostSimulation()">
              <option value="5">5 - Jeles / Kiváló</option>
              <option value="4">4 - Jó</option>
              <option value="3">3 - Közepes</option>
              <option value="2">2 - Elégséges</option>
              <option value="1">1 - Elégtelen</option>
            </select>
          </div>
          <div class="form-group">
            <label for="ghostGradeWeight">Súlyozás (%)</label>
            <select id="ghostGradeWeight" class="form-control" onchange="recalculateGhostSimulation()">
              <option value="100">100% (Normál órai jegy)</option>
              <option value="200">200% (Témazáró dolgozat)</option>
              <option value="50">50% (Kis felelet / házi)</option>
            </select>
          </div>
        </div>

        <div style="margin-top: 20px; background-color: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 18px;">
          <div style="display: flex; justify-content: space-between; margin-bottom: 12px;">
            <span style="color: var(--text-muted);">Jelenlegi tantárgyi átlag:</span>
            <strong id="ghostCurrentSubAvg" style="color: #fff;">--</strong>
          </div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 12px;">
            <span style="color: var(--text-muted);">Új szimulált tantárgyi átlag:</span>
            <strong id="ghostNewSubAvg" style="color: var(--primary); font-size: 1.1rem;">--</strong>
          </div>
          <div style="display: flex; justify-content: space-between; border-top: 1px solid var(--border); padding-top: 12px;">
            <span style="color: var(--text-muted);">Új szimulált összesített GPA:</span>
            <strong id="ghostNewOverallGpa" style="color: var(--success);">--</strong>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-primary" onclick="closeGhostSimulator()">Rendben</button>
      </div>
    </div>
  </div>

  <!-- Toast Notification -->
  <div id="toast" class="toast"></div>

  <script>
    const sessionToken = "$safeToken";
    let isUserAuthenticated = ${isAuthenticated ? 'true' : 'false'};
    let currentWeekOffset = 0;
    let cachedGrades = [];
    let cachedTeachers = [];
    let cachedMessages = [];
    let cachedSubjectAverages = {};
    let cachedSettings = {};
    let isTuiSettingsUnlocked = false;
    let schoolSearchDebounce = null;

    // Load saved accent theme from LocalStorage
    (function initAccentTheme() {
      const savedTheme = localStorage.getItem('pala_web_accent');
      if (savedTheme) {
        try {
          const t = JSON.parse(savedTheme);
          setWebAccentColor(t.name, t.hex, t.rgb, false);
        } catch (_) {}
      }
    })();

    function setWebAccentColor(name, hex, rgb, save = true) {
      document.documentElement.style.setProperty('--primary', hex);
      document.documentElement.style.setProperty('--primary-rgb', rgb);
      document.querySelectorAll('.color-swatch').forEach(el => el.classList.remove('active'));
      const activeEl = document.querySelector(`.color-swatch[onclick*="\${name}"]`);
      if (activeEl) activeEl.classList.add('active');
      if (save) {
        localStorage.setItem('pala_web_accent', JSON.stringify({ name, hex, rgb }));
        showToast('Színtéma sikeresen alkalmazva: ' + name);
      }
    }

    // Toggle TUI Settings lock
    function toggleTuiSettingsLock() {
      isTuiSettingsUnlocked = !isTuiSettingsUnlocked;
      const container = document.getElementById('tuiSettingsContainer');
      const badge = document.getElementById('tuiLockBadge');
      const btnText = document.getElementById('btnToggleTuiLockText');

      if (isTuiSettingsUnlocked) {
        container.classList.remove('tui-locked');
        badge.className = 'status-pill pill-green';
        badge.innerText = 'FELOLDVA';
        btnText.innerText = 'Zárolás visszakapcsolása';
        showToast('Terminális beállítások feloldva!');
      } else {
        container.classList.add('tui-locked');
        badge.className = 'status-pill pill-yellow';
        badge.innerText = 'ZÁROLVA (Webes nézet)';
        btnText.innerText = 'Zárolás feloldása';
      }
    }

    // Switch Tabs
    function switchTab(tabId) {
      document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
      
      const targetPane = document.getElementById('tab-' + tabId);
      if (targetPane) targetPane.classList.add('active');

      const navMap = {
        'dashboard': { idx: 0, title: 'Vezérlőpult' },
        'grades': { idx: 1, title: 'Érdemjegyek' },
        'timetable': { idx: 2, title: 'Órarend' },
        'homework': { idx: 3, title: 'Házi feladatok & Dolgozatok' },
        'messages': { idx: 4, title: 'Üzenetek' },
        'absences': { idx: 5, title: 'Mulasztások & Igazolások' },
        'stats': { idx: 6, title: 'Statisztika & Átlagok' },
        'profile': { idx: 7, title: 'Tanulói Adatlap' },
        'settings': { idx: 8, title: 'Beállítások' }
      };

      const info = navMap[tabId];
      if (info) {
        if (document.querySelectorAll('.nav-item')[info.idx]) {
          document.querySelectorAll('.nav-item')[info.idx].classList.add('active');
        }
        document.getElementById('pageHeader').innerText = info.title;
      }
    }

    // Toast helper
    function showToast(msg, type = 'success') {
      const toast = document.getElementById('toast');
      toast.className = 'toast ' + type + ' show';
      toast.innerText = msg;
      setTimeout(() => { toast.className = 'toast'; }, 3000);
    }

    // Authenticated API request
    async function apiFetch(path, options = {}) {
      if (!options.headers) options.headers = {};
      options.headers['X-Pala-Token'] = sessionToken;
      const res = await fetch(path, options);
      if (!res.ok) {
        const errData = await res.json().catch(() => ({}));
        throw new Error(errData.error || ('Hiba: ' + res.status));
      }
      return await res.json();
    }

    // Load All Data
    async function loadAllData() {
      try {
        await loadStudent();
        if (isUserAuthenticated) {
          loadGrades();
          loadTimetable();
          loadHomeworkAndExams();
          loadMessages();
          loadAbsences();
          loadTeachers();
          loadSettings();
        }
      } catch (e) {
        showToast('Hiba az adatok frissítésekor: ' + e.message, 'error');
      }
    }

    // 1. Student Info
    async function loadStudent() {
      try {
        const student = await apiFetch('/api/student');
        if (student && student.authenticated !== false) {
          isUserAuthenticated = true;
          document.getElementById('accountActionText').innerText = 'Fiókváltás';
          document.getElementById('setProfileStatus').innerText = student.name || 'Diák';

          // Sidebar profile
          document.getElementById('profileName').innerText = student.name || 'Diák';
          document.getElementById('profileInst').innerText = student.institutionName || 'Oktatási Intézmény';

          // Profile Tab
          document.getElementById('profFullName').innerText = student.name || '-';
          document.getElementById('profBirthName').innerText = student.birthName || student.name || '-';
          
          const bPlace = student.birthPlace || '';
          const bDate = student.birthDate ? student.birthDate.split('T')[0] : '';
          document.getElementById('profBirthPlaceDate').innerText = (bPlace && bDate) ? `\${bPlace}, \${bDate}` : (bPlace || bDate || '-');
          document.getElementById('profMothersName').innerText = student.mothersName || '-';
          document.getElementById('profUid').innerText = student.uid || 'N/A';
          document.getElementById('profEmail').innerText = student.email || '-';
          document.getElementById('profPhone').innerText = student.phone || '-';
          
          const addrs = student.addresses || [];
          document.getElementById('profAddresses').innerText = addrs.length > 0 ? addrs.join(', ') : '-';
          document.getElementById('profInstName').innerText = student.institutionName || '-';
          
          const dt = student.nextDowntime;
          document.getElementById('profDowntime').innerText = dt ? dt.replace('T', ' ').substring(0, 16) : 'Nincs tervezett leállás';

          // Guardians
          const gList = document.getElementById('profGuardiansList');
          const guardians = student.guardians || [];
          if (guardians.length === 0) {
            gList.innerHTML = '<div style="color: var(--text-muted);">Nincsenek regisztrált gondviselői adatok.</div>';
          } else {
            gList.innerHTML = guardians.map(g => `
              <div class="info-row">
                <div style="min-width: 0;">
                  <div style="font-weight: 600; color: #fff; word-break: break-word;">\${escapeHtml(g.name || 'Gondviselő')}</div>
                  <div style="font-size: 0.78rem; color: var(--text-muted);">\${escapeHtml(g.type || 'Gondviselő')}</div>
                </div>
                <div style="text-align: right; font-size: 0.85rem; min-width: 0; word-break: break-word;">
                  <div>\${escapeHtml(g.email || '')}</div>
                  <div style="color: var(--text-muted);">\${escapeHtml(g.phone || '')}</div>
                </div>
              </div>
            `).join('');
          }
        } else {
          isUserAuthenticated = false;
          document.getElementById('accountActionText').innerText = 'Bejelentkezés';
          document.getElementById('profileName').innerText = 'Nincs bejelentkezve';
          document.getElementById('profileInst').innerText = 'Kattints a belépéshez';
          openLoginModal();
        }
      } catch (_) {}
    }

    // 2. Grades & Stats
    async function loadGrades() {
      try {
        const data = await apiFetch('/api/grades');
        cachedGrades = data.grades || [];
        
        let sum = 0, count = 0;
        const counts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        const subSums = {};

        cachedGrades.forEach(g => {
          if (g.numericValue && g.numericValue >= 1 && g.numericValue <= 5) {
            const w = (g.weight || 100) / 100;
            sum += g.numericValue * w;
            count += w;
            counts[g.numericValue] = (counts[g.numericValue] || 0) + 1;

            const sub = g.subject || 'Egyéb';
            if (!subSums[sub]) subSums[sub] = { sum: 0, weight: 0, count: 0 };
            subSums[sub].sum += g.numericValue * w;
            subSums[sub].weight += w;
            subSums[sub].count += 1;
          }
        });

        const gpa = count > 0 ? (sum / count).toFixed(2) : '--';
        document.getElementById('dashGpa').innerText = gpa;

        cachedSubjectAverages = {};
        for (let s in subSums) {
          cachedSubjectAverages[s] = (subSums[s].sum / subSums[s].weight).toFixed(2);
        }

        renderGradesTable(cachedGrades);
        renderStats(counts, subSums);
      } catch (e) {
        console.error('Grades error:', e);
      }
    }

    function renderGradesTable(grades) {
      const tbody = document.querySelector('#gradesTable tbody');
      if (!grades || grades.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Nincsenek jegyek.</td></tr>';
        return;
      }
      tbody.innerHTML = grades.map(g => {
        const val = g.numericValue || g.textValue || '-';
        const badgeClass = g.numericValue ? 'grade-' + g.numericValue : 'grade-5';
        const dateStr = g.date ? g.date.split('T')[0] : '-';
        return `<tr>
          <td><span class="grade-badge \${badgeClass}">\${val}</span></td>
          <td style="font-weight: 600; color: #fff;">\${escapeHtml(g.subject || '-')}</td>
          <td>\${escapeHtml(g.theme || g.type || '-')}</td>
          <td>\${g.weight || 100}%</td>
          <td>\${dateStr}</td>
          <td>\${escapeHtml(g.teacherName || '-')}</td>
        </tr>`;
      }).join('');
    }

    function filterGrades() {
      const q = document.getElementById('gradeSearch').value.toLowerCase();
      const filtered = cachedGrades.filter(g => 
        (g.subject && g.subject.toLowerCase().includes(q)) ||
        (g.theme && g.theme.toLowerCase().includes(q)) ||
        (g.teacherName && g.teacherName.toLowerCase().includes(q))
      );
      renderGradesTable(filtered);
    }

    function renderStats(counts, subSums) {
      const totalNumeric = Object.values(counts).reduce((a,b) => a+b, 0);
      document.getElementById('statsTotalGrades').innerText = totalNumeric + ' db';
      const fivePct = totalNumeric > 0 ? ((counts[5] / totalNumeric) * 100).toFixed(0) : 0;
      document.getElementById('statsFivePct').innerText = fivePct + '% (' + counts[5] + ' db)';
      document.getElementById('statsOneCount').innerText = counts[1] + ' db';

      const chart = document.getElementById('gradeDistributionChart');
      const colors = { 5: 'var(--success)', 4: 'var(--primary)', 3: 'var(--warning)', 2: '#ff9500', 1: 'var(--danger)' };
      let html = '';
      for (let g = 5; g >= 1; g--) {
        const c = counts[g] || 0;
        const pct = totalNumeric > 0 ? ((c / totalNumeric) * 100).toFixed(0) : 0;
        html += `<div class="grade-chart-bar-container">
          <div class="grade-chart-label" style="color: \${colors[g]};">\${g}</div>
          <div class="grade-chart-track">
            <div class="grade-chart-bar" style="width: \${pct}%; background-color: \${colors[g]};"></div>
          </div>
          <div class="grade-chart-count">\${c} db (\${pct}%)</div>
        </div>`;
      }
      chart.innerHTML = html;

      const subTable = document.querySelector('#subjectAveragesTable tbody');
      const subKeys = Object.keys(subSums).sort((a,b) => {
        const avgA = subSums[a].sum / subSums[a].weight;
        const avgB = subSums[b].sum / subSums[b].weight;
        return avgB - avgA;
      });

      if (subKeys.length === 0) {
        subTable.innerHTML = '<tr><td colspan="4" style="text-align: center; color: var(--text-muted);">Nincsenek tantárgyi jegyek.</td></tr>';
        return;
      }

      subTable.innerHTML = subKeys.map(s => {
        const avg = (subSums[s].sum / subSums[s].weight).toFixed(2);
        const cnt = subSums[s].count;
        let pill = 'pill-green';
        let status = 'Kiváló';
        if (avg < 2.0) { pill = 'pill-red'; status = 'Bukás veszély!'; }
        else if (avg < 3.0) { pill = 'pill-yellow'; status = 'Figyelmeztetés'; }
        else if (avg < 4.0) { pill = 'pill-orange'; status = 'Jó'; }

        return `<tr>
          <td style="font-weight: 600; color: #fff;">\${escapeHtml(s)}</td>
          <td style="font-weight: 700; font-size: 1.05rem;">\${avg}</td>
          <td>\${cnt} db jegy</td>
          <td><span class="status-pill \${pill}">\${status}</span></td>
        </tr>`;
      }).join('');
    }

    // 3. Timetable
    async function loadTimetable() {
      try {
        const data = await apiFetch('/api/timetable?weekOffset=' + currentWeekOffset);
        const lessons = data.lessons || [];
        
        if (data.startDate && data.endDate) {
          const s = data.startDate.split('T')[0];
          const e = data.endDate.split('T')[0];
          document.getElementById('timetableWeekLabel').innerText = `\${s} - \${e}`;
        }

        updateLiveCountdown(lessons);
        renderTodayTable(lessons);
        renderWeeklyGrid(lessons);
      } catch (e) {
        console.error('Timetable error:', e);
      }
    }

    function changeWeek(delta) {
      if (delta === 0) currentWeekOffset = 0;
      else currentWeekOffset += delta;
      loadTimetable();
    }

    function updateLiveCountdown(lessons) {
      const now = new Date();
      const todayStr = now.toISOString().split('T')[0];
      const todayLessons = lessons.filter(l => l.startTime && l.startTime.startsWith(todayStr));
      
      document.getElementById('dashLessonsCount').innerText = todayLessons.length + ' óra';

      const wrap = document.getElementById('lessonProgressWrap');
      const fill = document.getElementById('lessonProgressFill');

      if (todayLessons.length === 0) {
        document.getElementById('countdownTitle').innerText = 'Ma nincsenek tanítási óráid!';
        document.getElementById('countdownSub').innerText = 'Jó pihenést a mai napra!';
        wrap.style.display = 'none';
        return;
      }

      let currentLesson = null, nextLesson = null;
      for (let l of todayLessons) {
        const st = new Date(l.startTime);
        const et = new Date(l.endTime);
        if (now >= st && now <= et) {
          currentLesson = l;
          break;
        } else if (st > now && !nextLesson) {
          nextLesson = l;
        }
      }

      if (currentLesson) {
        const st = new Date(currentLesson.startTime);
        const et = new Date(currentLesson.endTime);
        const totalDuration = et - st;
        const elapsed = now - st;
        const pct = Math.min(100, Math.max(0, (elapsed / totalDuration) * 100));

        const diffMins = Math.max(0, Math.round((et - now) / 60000));
        document.getElementById('countdownTitle').innerText = `Most zajlik: \${escapeHtml(currentLesson.subject)}`;
        document.getElementById('countdownSub').innerText = `Hátra van még: \${diffMins} perc (Terem: \${escapeHtml(currentLesson.room || 'N/A')})`;
        wrap.style.display = 'block';
        fill.style.width = pct + '%';
      } else if (nextLesson) {
        const diffMins = Math.max(0, Math.round((new Date(nextLesson.startTime) - now) / 60000));
        document.getElementById('countdownTitle').innerText = `Következő óra: \${escapeHtml(nextLesson.subject)}`;
        document.getElementById('countdownSub').innerText = `Kezdődik \${diffMins} perc múlva (Terem: \${escapeHtml(nextLesson.room || 'N/A')})`;
        wrap.style.display = 'none';
      } else {
        document.getElementById('countdownTitle').innerText = 'A mai óráid véget értek!';
        document.getElementById('countdownSub').innerText = 'Szép estét és jó felkészülést holnapra!';
        wrap.style.display = 'none';
      }
    }

    function renderTodayTable(lessons) {
      const todayStr = new Date().toISOString().split('T')[0];
      const todayLessons = lessons.filter(l => l.startTime && l.startTime.startsWith(todayStr));
      const tbody = document.querySelector('#dashTodayTable tbody');

      if (todayLessons.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Mára nincs több óra.</td></tr>';
        return;
      }

      todayLessons.sort((a,b) => (a.lessonNumber || 0) - (b.lessonNumber || 0));
      tbody.innerHTML = todayLessons.map(l => {
        const start = l.startTime ? l.startTime.split('T')[1].substring(0,5) : '';
        const end = l.endTime ? l.endTime.split('T')[1].substring(0,5) : '';
        const timeRange = start && end ? `\${start} - \${end}` : '-';
        const isCancelled = l.isCancelled;
        const statusPill = isCancelled 
          ? '<span class="status-pill pill-red">Elmarad</span>' 
          : '<span class="status-pill pill-green">Megtartva</span>';
        
        return `<tr style="\${isCancelled ? 'opacity: 0.5;' : ''}">
          <td style="font-weight: 700;">\${l.lessonNumber || '-'}.</td>
          <td>\${timeRange}</td>
          <td style="font-weight: 600; color: #fff;">\${escapeHtml(l.subject || '-')}</td>
          <td>\${escapeHtml(l.room || '-')}</td>
          <td>\${escapeHtml(l.teacherName || '-')}</td>
          <td>\${statusPill}</td>
        </tr>`;
      }).join('');
    }

    function renderWeeklyGrid(lessons) {
      const grid = document.getElementById('timetableGrid');
      const days = ['Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek'];
      
      let html = '<div class="tt-header">#</div>';
      days.forEach(d => { html += `<div class="tt-header">\${d}</div>`; });

      for (let period = 1; period <= 8; period++) {
        html += `<div class="tt-period-num">\${period}.</div>`;
        for (let dayIdx = 1; dayIdx <= 5; dayIdx++) {
          const matching = lessons.find(l => {
            if (!l.startTime) return false;
            const date = new Date(l.startTime);
            const d = date.getDay();
            return d === dayIdx && l.lessonNumber === period;
          });

          if (matching) {
            const cancelClass = matching.isCancelled ? 'tt-cancelled' : '';
            html += `<div class="tt-cell \${cancelClass}">
              <div class="tt-subject">\${escapeHtml(matching.subject || '-')}</div>
              <div class="tt-room">\${escapeHtml(matching.room || '')}</div>
            </div>`;
          } else {
            html += `<div class="tt-cell" style="background-color: transparent; border-style: dashed;"></div>`;
          }
        }
      }
      grid.innerHTML = html;
    }

    // 4. Homework & Exams
    async function loadHomeworkAndExams() {
      try {
        const exams = await apiFetch('/api/exams');
        document.getElementById('dashExamsCount').innerText = exams.length;
        
        const examsTbody = document.querySelector('#examsTable tbody');
        if (!exams || exams.length === 0) {
          examsTbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: var(--text-muted);">Nincsenek bejelentett dolgozatok.</td></tr>';
        } else {
          examsTbody.innerHTML = exams.map(e => `<tr>
            <td style="font-weight: 600;">\${e.date ? e.date.split('T')[0] : '-'}</td>
            <td style="font-weight: 600; color: #fff;">\${escapeHtml(e.subject || '-')}</td>
            <td><span class="status-pill pill-orange">\${escapeHtml(e.mode || 'Dolgozat')}</span></td>
            <td>\${escapeHtml(e.theme || '-')}</td>
          </tr>`).join('');
        }

        const homework = await apiFetch('/api/homework');
        const hwTbody = document.querySelector('#homeworkTable tbody');
        if (!homework || homework.length === 0) {
          hwTbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--text-muted);">Nincsenek aktív házi feladatok.</td></tr>';
        } else {
          const completedHw = JSON.parse(localStorage.getItem('pala_completed_hw') || '{}');
          hwTbody.innerHTML = homework.map((h, idx) => {
            const hwId = h.uid || ('hw_' + idx);
            const isDone = completedHw[hwId] === true;
            return `<tr id="hw_row_\${hwId}" class="\${isDone ? 'hw-done' : ''}">
              <td><input type="checkbox" class="hw-checkbox" \${isDone ? 'checked' : ''} onchange="toggleHomeworkDone('\${hwId}')" /></td>
              <td style="font-weight: 600; color: var(--warning);">\${h.deadline ? h.deadline.split('T')[0] : '-'}</td>
              <td style="font-weight: 600; color: #fff;">\${escapeHtml(h.subject || '-')}</td>
              <td>\${escapeHtml(h.text || '-')}</td>
              <td>\${h.date ? h.date.split('T')[0] : '-'}</td>
            </tr>`;
          }).join('');
        }
      } catch (e) {
        console.error('Homework/Exams error:', e);
      }
    }

    function toggleHomeworkDone(hwId) {
      const completedHw = JSON.parse(localStorage.getItem('pala_completed_hw') || '{}');
      completedHw[hwId] = !completedHw[hwId];
      localStorage.setItem('pala_completed_hw', JSON.stringify(completedHw));
      const row = document.getElementById('hw_row_' + hwId);
      if (row) {
        if (completedHw[hwId]) row.classList.add('hw-done');
        else row.classList.remove('hw-done');
      }
    }

    // 5. Messages
    async function loadMessages() {
      try {
        cachedMessages = await apiFetch('/api/messages');
        const tbody = document.querySelector('#messagesTable tbody');
        if (!cachedMessages || cachedMessages.length === 0) {
          tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: var(--text-muted);">Nincsenek üzenetek.</td></tr>';
          return;
        }
        tbody.innerHTML = cachedMessages.map((m, idx) => `<tr>
          <td>\${m.date ? m.date.split('T')[0] : '-'}</td>
          <td style="font-weight: 600; color: #fff;">\${escapeHtml(m.sender || '-')}</td>
          <td>\${escapeHtml(m.subject || '-')}</td>
          <td><button class="btn" onclick="openMsgViewer(\${idx})">Megnyitás</button></td>
        </tr>`).join('');
      } catch (e) {
        console.error('Messages error:', e);
      }
    }

    function openMsgViewer(idx) {
      const msg = cachedMessages[idx];
      if (!msg) return;
      document.getElementById('viewMsgSubject').innerText = msg.subject || 'Üzenet';
      document.getElementById('viewMsgSender').innerText = msg.sender || 'Ismeretlen feladó';
      document.getElementById('viewMsgDate').innerText = msg.date ? msg.date.replace('T', ' ').substring(0, 16) : '-';
      document.getElementById('viewMsgBody').innerText = msg.text || 'Nincs szövegtartalom.';

      document.getElementById('btnReplyMsg').onclick = () => {
        closeMsgViewer();
        openComposerModal('Re: ' + (msg.subject || ''), '\\n\\n--- Eredeti üzenet ---\\n' + (msg.text || ''));
      };

      document.getElementById('messageViewerModal').classList.add('open');
    }

    function closeMsgViewer() {
      document.getElementById('messageViewerModal').classList.remove('open');
    }

    // 6. Absences
    async function loadAbsences() {
      try {
        const data = await apiFetch('/api/absences');
        const absences = data.absences || [];
        const quota = data.parentalQuota || 5;
        const usedDays = data.usedParentalDays || 0;

        document.getElementById('dashQuota').innerText = `\${usedDays} / \${quota}`;
        document.getElementById('absTotalHours').innerText = `\${absences.length} óra`;
        
        const dangerPct = ((absences.length / 250) * 100).toFixed(1);
        document.getElementById('absDangerPct').innerText = `\${dangerPct}%`;
        document.getElementById('absQuotaStatus').innerText = `\${usedDays} / \${quota} nap`;

        const pending = absences.filter(a => {
          const s = (a.status || '').toLowerCase();
          return s.includes('igazolando') || s.includes('igazolandó') || s.includes('igazolatlan');
        });
        document.getElementById('absPendingCount').innerText = `\${pending.length} óra`;

        const tbody = document.querySelector('#absencesTable tbody');
        if (absences.length === 0) {
          tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--text-muted);">Nincsenek mulasztások.</td></tr>';
          return;
        }
        tbody.innerHTML = absences.map(a => {
          const s = (a.status || '').toLowerCase();
          let pill = 'pill-yellow';
          if (s.includes('igazolt') && !s.includes('igazolatlan')) pill = 'pill-green';
          else if (s.includes('igazolatlan')) pill = 'pill-red';
          else if (s.includes('nem írt') || s.includes('elmúlt')) pill = 'pill-gray';

          return `<tr>
            <td style="font-weight: 600;">\${a.date ? a.date.split('T')[0] : '-'}</td>
            <td style="font-weight: 600; color: #fff;">\${escapeHtml(a.subject || '-')}</td>
            <td>\${escapeHtml(a.type || 'Hiányzás')}</td>
            <td><span class="status-pill \${pill}">\${escapeHtml(a.status || '-')}</span></td>
            <td>\${a.delayMinutes ? a.delayMinutes + ' perc' : '-'}</td>
          </tr>`;
        }).join('');
      } catch (e) {
        console.error('Absences error:', e);
      }
    }

    // 7. Teachers for Composer
    async function loadTeachers() {
      try {
        cachedTeachers = await apiFetch('/api/teachers');
        const select = document.getElementById('compRecipient');
        if (cachedTeachers && cachedTeachers.length > 0) {
          select.innerHTML = cachedTeachers.map(t => {
            const id = t.azonosito || t.id;
            const name = t.nev || t.name || 'Tanár';
            const sub = t.tantargyak || t.subjects || '';
            const label = sub ? `\${name} (\${sub})` : name;
            return `<option value="\${id}">\${escapeHtml(label)}</option>`;
          }).join('');
        }
      } catch (_) {}
    }

    // 8. Settings & Aliases
    async function loadSettings() {
      try {
        cachedSettings = await apiFetch('/api/settings');
        if (cachedSettings) {
          document.getElementById('setParentalQuotaInput').value = cachedSettings.parentalQuota || 5;
          document.getElementById('setShowAsciiBanner').checked = cachedSettings.showAsciiBanner !== false;
          renderAliasesTable(cachedSettings.aliases || {});
        }
      } catch (_) {}
    }

    function renderAliasesTable(aliases) {
      const tbody = document.querySelector('#aliasesTable tbody');
      const keys = Object.keys(aliases);
      if (keys.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3" style="text-align: center; color: var(--text-muted);">Nincsenek egyéni átnevezések beállítva.</td></tr>';
        return;
      }
      tbody.innerHTML = keys.map(k => `<tr>
        <td style="font-weight: 600; color: #fff;">\${escapeHtml(k)}</td>
        <td style="color: var(--primary); font-weight: 600;">\${escapeHtml(aliases[k])}</td>
        <td><button class="btn btn-danger" onclick="deleteAlias('\${escapeHtml(k)}')">Törlés</button></td>
      </tr>`).join('');
    }

    async function saveParentalQuotaSetting() {
      const q = parseInt(document.getElementById('setParentalQuotaInput').value);
      if (isNaN(q) || q < 1) {
        showToast('Érvénytelen keret érték!', 'error');
        return;
      }
      try {
        await apiFetch('/api/settings', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ parentalQuota: q })
        });
        showToast('Szülői keret sikeresen mentve: ' + q + ' nap', 'success');
        loadAbsences();
      } catch (e) {
        showToast('Hiba a mentéskor: ' + e.message, 'error');
      }
    }

    async function saveGeneralSettings() {
      const banner = document.getElementById('setShowAsciiBanner').checked;
      try {
        await apiFetch('/api/settings', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ showAsciiBanner: banner })
        });
        showToast('Beállítások sikeresen mentve!', 'success');
      } catch (e) {
        showToast('Hiba a beállítások mentésekor: ' + e.message, 'error');
      }
    }

    async function addNewAlias() {
      const orig = document.getElementById('newAliasOriginal').value.trim();
      const custom = document.getElementById('newAliasCustom').value.trim();
      if (!orig || !custom) {
        showToast('Kérlek töltsd ki mindkét mezőt!', 'error');
        return;
      }
      try {
        const res = await apiFetch('/api/aliases', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ original: orig, alias: custom })
        });
        document.getElementById('newAliasOriginal').value = '';
        document.getElementById('newAliasCustom').value = '';
        renderAliasesTable(res.aliases || {});
        showToast(`Átnevezés elmentve: \${orig} -> \${custom}`, 'success');
        loadGrades();
        loadTimetable();
      } catch (e) {
        showToast('Hiba az alias mentésekor: ' + e.message, 'error');
      }
    }

    async function deleteAlias(orig) {
      try {
        const res = await apiFetch('/api/delete-alias', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ original: orig })
        });
        renderAliasesTable(res.aliases || {});
        showToast(`Átnevezés törölve: \${orig}`, 'success');
        loadGrades();
        loadTimetable();
      } catch (e) {
        showToast('Hiba az alias törlésekor: ' + e.message, 'error');
      }
    }

    function clearWebStorage() {
      localStorage.removeItem('pala_completed_hw');
      showToast('Helyi böngésző teendő lista törölve!', 'success');
      loadAllData();
    }

    // 9. Login Modal & Operations
    function openLoginModal() {
      document.getElementById('loginModal').classList.add('open');
      document.getElementById('loginErrorMsg').style.display = 'none';
    }

    function closeLoginModal() {
      document.getElementById('loginModal').classList.remove('open');
    }

    function switchLoginTab(tab) {
      const realTab = document.getElementById('loginRealForm');
      const demoTab = document.getElementById('loginDemoForm');
      const realFooter = document.getElementById('loginRealFooter');
      const btnReal = document.getElementById('btnTabRealLogin');
      const btnDemo = document.getElementById('btnTabDemoLogin');

      if (tab === 'real') {
        realTab.style.display = 'block';
        demoTab.style.display = 'none';
        realFooter.style.display = 'flex';
        btnReal.className = 'btn btn-primary';
        btnDemo.className = 'btn';
      } else {
        realTab.style.display = 'none';
        demoTab.style.display = 'block';
        realFooter.style.display = 'none';
        btnReal.className = 'btn';
        btnDemo.className = 'btn btn-primary';
      }
    }

    function onSchoolSearchInput() {
      clearTimeout(schoolSearchDebounce);
      const q = document.getElementById('loginSchoolSearch').value.trim();
      const suggBox = document.getElementById('schoolSuggestions');
      if (q.length < 2) {
        suggBox.style.display = 'none';
        return;
      }
      schoolSearchDebounce = setTimeout(async () => {
        try {
          const res = await apiFetch('/api/schools?q=' + encodeURIComponent(q));
          const keys = Object.keys(res || {});
          if (keys.length > 0) {
            suggBox.innerHTML = keys.slice(0, 8).map(code => `
              <div style="padding: 8px 12px; cursor: pointer; border-bottom: 1px solid rgba(255,255,255,0.05); font-size: 0.85rem;" onclick="selectSchoolSuggest('\${code}', '\${escapeHtml(res[code])}')">
                <div style="font-weight: 600; color: #fff;">\${escapeHtml(res[code])}</div>
                <div style="font-size: 0.75rem; color: var(--text-muted);">\${code}</div>
              </div>
            `).join('');
            suggBox.style.display = 'block';
          } else {
            suggBox.style.display = 'none';
          }
        } catch (_) {
          suggBox.style.display = 'none';
        }
      }, 300);
    }

    function selectSchoolSuggest(code, name) {
      document.getElementById('loginInstituteCode').value = code;
      document.getElementById('loginSchoolSearch').value = name;
      document.getElementById('schoolSuggestions').style.display = 'none';
    }

    async function submitRealLogin() {
      const inst = document.getElementById('loginInstituteCode').value.trim();
      const user = document.getElementById('loginUsername').value.trim();
      const pass = document.getElementById('loginPassword').value.trim();
      const errBox = document.getElementById('loginErrorMsg');
      const submitBtn = document.getElementById('btnLoginSubmit');

      if (!inst || !user || !pass) {
        errBox.innerText = 'Kérlek töltsd ki az összes mezőt!';
        errBox.style.display = 'block';
        return;
      }

      errBox.style.display = 'none';
      submitBtn.innerText = 'Bejelentkezés folyamatban...';
      submitBtn.disabled = true;

      try {
        const res = await apiFetch('/api/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ instituteCode: inst, username: user, password: pass })
        });
        showToast('Sikeres bejelentkezés: ' + (res.name || user), 'success');
        closeLoginModal();
        loadAllData();
      } catch (e) {
        errBox.innerText = e.message || 'Hibás bejelentkezési adatok!';
        errBox.style.display = 'block';
      } finally {
        submitBtn.innerText = 'Bejelentkezés';
        submitBtn.disabled = false;
      }
    }

    async function submitDemoLogin() {
      try {
        await apiFetch('/api/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ isDemo: true })
        });
        showToast('Sikeres belépés Demó módban (Teszt Elek)!', 'success');
        closeLoginModal();
        loadAllData();
      } catch (e) {
        showToast('Hiba a belépés során: ' + e.message, 'error');
      }
    }

    async function logoutSession() {
      try {
        await apiFetch('/api/logout', { method: 'POST' });
        showToast('Sikeres kijelentkezés!');
        isUserAuthenticated = false;
        loadStudent();
      } catch (e) {
        showToast('Hiba a kijelentkezéskor: ' + e.message, 'error');
      }
    }

    // Composer Modal controls
    function openComposerModal(subject = '', prefill = '') {
      document.getElementById('compSubject').value = subject;
      document.getElementById('compText').value = prefill;
      document.getElementById('composerModal').classList.add('open');
    }

    function closeComposerModal() {
      document.getElementById('composerModal').classList.remove('open');
    }

    async function sendMessageFromModal() {
      const recipientId = document.getElementById('compRecipient').value;
      const subject = document.getElementById('compSubject').value.trim();
      const text = document.getElementById('compText').value.trim();

      if (!recipientId || !subject || !text) {
        showToast('Kérlek töltsd ki az összes mezőt!', 'error');
        return;
      }

      try {
        await apiFetch('/api/send-message', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            recipientIds: [parseInt(recipientId)],
            subject: subject,
            text: text
          })
        });
        showToast('Üzenet sikeresen elküldve!', 'success');
        closeComposerModal();
        loadMessages();
      } catch (e) {
        showToast('Hiba az üzenet küldésekor: ' + e.message, 'error');
      }
    }

    function openExcuseGenerator() {
      const subj = 'Szülői igazolás mulasztásról';
      const text = `Tisztelt Osztályfőnök!\\n\\nEzúton igazolom gyermekem hiányzását szülői jogköröm alapján.\\n\\nKelt: \${new Date().toISOString().split('T')[0]}\\nTisztelettel: Gondviselő`;
      openComposerModal(subj, text);
    }

    // Ghost Simulator Modal
    function openGhostSimulator() {
      const select = document.getElementById('ghostSubjectSelect');
      const subs = Object.keys(cachedSubjectAverages);
      if (subs.length === 0) {
        showToast('Nincsenek elérhető tantárgyak a szimulációhoz.', 'error');
        return;
      }
      select.innerHTML = subs.map(s => `<option value="\${s}">\${escapeHtml(s)}</option>`).join('');
      recalculateGhostSimulation();
      document.getElementById('ghostModal').classList.add('open');
    }

    function closeGhostSimulator() {
      document.getElementById('ghostModal').classList.remove('open');
    }

    function recalculateGhostSimulation() {
      const sub = document.getElementById('ghostSubjectSelect').value;
      const simVal = parseInt(document.getElementById('ghostGradeValue').value);
      const simWeight = parseInt(document.getElementById('ghostGradeWeight').value) / 100;

      let subSum = 0, subWeight = 0;
      let totalSum = 0, totalWeight = 0;

      cachedGrades.forEach(g => {
        if (g.numericValue && g.numericValue >= 1 && g.numericValue <= 5) {
          const w = (g.weight || 100) / 100;
          totalSum += g.numericValue * w;
          totalWeight += w;

          if (g.subject === sub) {
            subSum += g.numericValue * w;
            subWeight += w;
          }
        }
      });

      const curSubAvg = subWeight > 0 ? (subSum / subWeight).toFixed(2) : '--';
      const newSubAvg = (subWeight + simWeight) > 0 ? ((subSum + simVal * simWeight) / (subWeight + simWeight)).toFixed(2) : simVal.toFixed(2);
      const newTotalGpa = (totalWeight + simWeight) > 0 ? ((totalSum + simVal * simWeight) / (totalWeight + simWeight)).toFixed(2) : simVal.toFixed(2);

      document.getElementById('ghostCurrentSubAvg').innerText = curSubAvg;
      document.getElementById('ghostNewSubAvg').innerText = newSubAvg;
      document.getElementById('ghostNewOverallGpa').innerText = newTotalGpa;
    }

    function escapeHtml(str) {
      if (!str) return '';
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    // Initial load
    window.addEventListener('DOMContentLoaded', loadAllData);
  </script>
</body>
</html>''';
  }
}


