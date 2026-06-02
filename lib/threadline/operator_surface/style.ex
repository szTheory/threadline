if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc """
    Provides isolated CSS for the Threadline Operator Surface.
    """

    import Phoenix.Component

    def css(assigns) do
      ~H"""
      <style>
        .threadline-ui {
          --tl-space-1: 4px;
          --tl-space-2: 8px;
          --tl-space-3: 12px;
          --tl-space-4: 16px;
          --tl-space-5: 20px;
          --tl-space-6: 24px;
          --tl-space-8: 32px;
          --tl-space-10: 40px;
          --tl-space-12: 48px;

          --tl-font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          --tl-font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
          --tl-font-size-xs: 11px;
          --tl-font-size-sm: 12px;
          --tl-font-size-body: 14px;
          --tl-font-size-label: 12px;
          --tl-font-size-ui: 13px;
          --tl-font-size-heading: 18px;
          --tl-font-size-title: 20px;
          --tl-line-body: 1.5;
          --tl-line-label: 1.4;
          --tl-line-heading: 1.2;
          --tl-weight-regular: 400;
          --tl-weight-strong: 600;

          --tl-color-bg: #FFFFFF;
          --tl-color-surface: #F9FAFB;
          --tl-color-surface-raised: #FFFFFF;
          --tl-color-border: #E5E7EB;
          --tl-color-border-strong: #D1D5DB;
          --tl-color-text: #111827;
          --tl-color-muted: #6B7280;
          --tl-color-accent: #3B82F6;
          --tl-color-accent-strong: #2563EB;
          --tl-color-danger: #EF4444;
          --tl-color-danger-bg: rgba(239, 68, 68, 0.07);
          --tl-color-warning-bg: #FEF3C7;
          --tl-color-warning-text: #92400E;
          --tl-color-warning-border: #F59E0B;
          --tl-color-success-bg: #ECFDF5;
          --tl-color-success-text: #047857;
          --tl-color-success-border: rgba(4, 120, 87, 0.24);
          --tl-color-info-bg: rgba(59, 130, 246, 0.08);
          --tl-color-info-text: #2563EB;
          --tl-color-info-border: rgba(59, 130, 246, 0.25);
          --tl-color-neutral-bg: #F9FAFB;
          --tl-color-neutral-text: #4B5563;
          --tl-color-neutral-border: #E5E7EB;

          --tl-radius-xs: 3px;
          --tl-radius-sm: 4px;
          --tl-radius-md: 6px;
          --tl-radius-lg: 8px;
          --tl-radius-xl: 12px;
          --tl-radius-pill: 999px;
          --tl-shadow-border: inset 0 0 0 1px var(--tl-color-border);
          --tl-shadow-subtle: 0 1px 2px rgba(17, 24, 39, 0.06), 0 1px 3px rgba(17, 24, 39, 0.04);
          --tl-shadow-popover: 0 8px 24px rgba(17, 24, 39, 0.08);
          --tl-shadow-raised: 0 8px 24px rgba(17, 24, 39, 0.08);
          --tl-z-toolbar: 20;
          --tl-z-header: 30;
          --tl-z-subview: 50;
          --tl-header-height: 44px;
          --tl-control-height: 40px;
          --tl-hit-area: 40px;
          --tl-focus-ring: 0 0 0 3px rgba(59, 130, 246, 0.22);
          --tl-motion-fast: 120ms;
          --tl-motion-base: 180ms;
          --tl-ease-standard: cubic-bezier(0.2, 0, 0, 1);
          --tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);

          min-height: 100%;
          font-family: var(--tl-font-family);
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          color: var(--tl-color-text);
          background: var(--tl-color-bg);
          -webkit-font-smoothing: antialiased;
          text-rendering: optimizeLegibility;
        }

        .threadline-ui *,
        .threadline-ui *::before,
        .threadline-ui *::after {
          box-sizing: border-box;
        }

        .threadline-ui a {
          color: var(--tl-color-accent);
          text-decoration: none;
          transition-property: color, background-color, border-color, box-shadow, transform;
          transition-duration: var(--tl-transition-fast);
        }

        .threadline-ui a:hover {
          color: var(--tl-color-accent-strong);
          text-decoration: underline;
        }

        .threadline-ui button,
        .threadline-ui input,
        .threadline-ui select {
          font: inherit;
        }

        .threadline-ui button,
        .threadline-ui [role="button"],
        .threadline-ui input,
        .threadline-ui select,
        .threadline-ui a {
          outline: none;
        }

        .threadline-ui button:focus-visible,
        .threadline-ui [role="button"]:focus-visible,
        .threadline-ui input:focus-visible,
        .threadline-ui select:focus-visible,
        .threadline-ui a:focus-visible,
        .threadline-ui summary:focus-visible {
          box-shadow: var(--tl-focus-ring);
        }

        .threadline-ui code,
        .threadline-ui pre,
        .tl-code {
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
        }

        .tl-muted {
          color: var(--tl-color-muted);
        }

        .threadline-ui pre {
          margin: 0;
          overflow: auto;
          white-space: pre-wrap;
          overflow-wrap: anywhere;
        }

        .tl-topbar {
          position: sticky;
          top: 0;
          z-index: var(--tl-z-header);
          min-height: var(--tl-header-height);
          display: flex;
          align-items: center;
          gap: var(--tl-space-3);
          padding: var(--tl-space-1) var(--tl-space-4);
          background: rgba(255, 255, 255, 0.96);
          border-bottom: 1px solid var(--tl-color-border);
          backdrop-filter: blur(8px);
          font-size: var(--tl-font-size-label);
        }

        .tl-topbar__brand {
          display: inline-flex;
          align-items: center;
          min-height: 32px;
          color: var(--tl-color-text);
          font-weight: var(--tl-weight-strong);
          letter-spacing: 0;
          text-decoration: none;
          white-space: nowrap;
        }

        .tl-topbar__brand:hover {
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-topbar__nav {
          display: flex;
          flex: 1 1 auto;
          align-items: center;
          gap: 2px;
          min-width: 0;
          overflow-x: auto;
          scrollbar-width: none;
        }

        .tl-topbar__nav::-webkit-scrollbar {
          display: none;
        }

        .tl-topbar__nav-item {
          display: inline-flex;
          align-items: center;
          min-height: 32px;
          padding: var(--tl-space-1) var(--tl-space-2);
          border-radius: var(--tl-radius-md);
          color: var(--tl-color-muted);
          font-weight: var(--tl-weight-strong);
          text-decoration: none;
          white-space: nowrap;
        }

        .tl-topbar__nav-item:hover {
          background: var(--tl-color-surface);
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-topbar__nav-item--active {
          background: rgba(59, 130, 246, 0.09);
          color: var(--tl-color-accent-strong);
        }

        .tl-topbar__status {
          display: flex;
          align-items: center;
          gap: var(--tl-space-2);
          white-space: nowrap;
        }

        .tl-topbar__stale {
          color: var(--tl-color-muted);
          font-size: 11px;
          font-variant-numeric: tabular-nums;
        }

        .tl-page {
          padding: var(--tl-space-4);
        }

        .tl-page__header {
          display: flex;
          flex-wrap: wrap;
          align-items: flex-start;
          justify-content: space-between;
          gap: var(--tl-space-3);
          margin-bottom: var(--tl-space-4);
        }

        .tl-page__title {
          margin: 0 0 var(--tl-space-1);
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
          text-wrap: balance;
        }

        .tl-page__lede,
        .tl-page__meta {
          margin: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          text-wrap: pretty;
        }

        .tl-page__actions,
        .tl-nav {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-toolbar {
          position: sticky;
          top: var(--tl-header-height);
          z-index: var(--tl-z-toolbar);
          padding: var(--tl-space-4);
          background: rgba(255, 255, 255, 0.97);
          border-bottom: 1px solid var(--tl-color-border);
          box-shadow: 0 1px 0 rgba(17, 24, 39, 0.02);
          backdrop-filter: blur(8px);
        }

        .tl-toolbar__form {
          display: flex;
          flex-wrap: wrap;
          align-items: flex-end;
          gap: var(--tl-space-3);
        }

        .tl-toolbar__field {
          display: flex;
          min-width: 148px;
          flex-direction: column;
          gap: var(--tl-space-1);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-toolbar__field--wide {
          min-width: min(280px, 100%);
          flex: 1 1 240px;
        }

        .tl-toolbar__control,
        .tl-control {
          min-height: var(--tl-control-height);
          padding: var(--tl-space-2) var(--tl-space-3);
          border: 1px solid var(--tl-color-border-strong);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface-raised);
          color: var(--tl-color-text);
          transition-property: border-color, box-shadow, background-color;
          transition-duration: var(--tl-transition-fast);
        }

        .tl-toolbar__control[type="datetime-local"],
        .tl-control[type="datetime-local"],
        .threadline-ui select.tl-toolbar__control,
        .threadline-ui select.tl-control {
          min-width: 178px;
        }

        .tl-toolbar__control:disabled,
        .tl-control:disabled {
          color: var(--tl-color-muted);
          background: var(--tl-color-surface);
          cursor: not-allowed;
        }

        .tl-toolbar__control:focus,
        .tl-control:focus {
          border-color: var(--tl-color-accent);
        }

        .tl-toolbar__hint,
        .tl-hint {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-toolbar__actions {
          display: flex;
          flex: 1 1 320px;
          flex-wrap: wrap;
          align-items: center;
          justify-content: flex-end;
          gap: var(--tl-space-2);
          margin-left: auto;
        }

        .tl-action-group {
          display: inline-flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-action-group--secondary {
          padding-left: var(--tl-space-2);
          border-left: 1px solid var(--tl-color-border);
        }

        .tl-toolbar__saved-views {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-3);
          margin-top: var(--tl-space-3);
          padding-top: var(--tl-space-3);
          border-top: 1px solid var(--tl-color-border);
        }

        .tl-toolbar__saved-list {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          margin: 0;
          padding: 0;
          list-style: none;
        }

        .tl-toolbar__saved-item {
          display: inline-flex;
          align-items: center;
          gap: var(--tl-space-1);
        }

        .tl-button {
          min-height: var(--tl-hit-area);
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: var(--tl-space-1);
          padding: var(--tl-space-2) var(--tl-space-3);
          border: 1px solid transparent;
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface-raised);
          color: var(--tl-color-text);
          cursor: pointer;
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
          text-decoration: none;
          transition-property: color, background-color, border-color, box-shadow, transform;
          transition-duration: var(--tl-transition-fast);
        }

        .tl-button:hover {
          text-decoration: none;
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-button:active {
          transform: translateY(1px);
        }

        .tl-button--compact {
          min-height: 32px;
          padding: var(--tl-space-1) var(--tl-space-3);
        }

        .tl-button--primary {
          background: var(--tl-color-accent);
          border-color: var(--tl-color-accent);
          color: #FFFFFF;
        }

        .threadline-ui a.tl-button--primary {
          color: #FFFFFF;
        }

        .tl-button--primary:hover {
          background: var(--tl-color-accent-strong);
          border-color: var(--tl-color-accent-strong);
          color: #FFFFFF;
        }

        .tl-button--secondary {
          border-color: var(--tl-color-border);
          color: var(--tl-color-text);
        }

        .tl-button--ghost {
          border-color: transparent;
          background: transparent;
          color: var(--tl-color-muted);
        }

        .tl-button--danger {
          color: var(--tl-color-danger);
        }

        .tl-button--icon {
          width: var(--tl-hit-area);
          padding: 0;
          font-size: 16px;
        }

        .tl-link {
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
        }

        .tl-link--back {
          color: var(--tl-color-muted);
        }

        .tl-link--deep {
          color: var(--tl-color-accent);
        }

        .tl-chip {
          display: inline-flex;
          align-items: center;
          min-height: 24px;
          padding: var(--tl-space-1) var(--tl-space-2);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-pill);
          background: var(--tl-color-surface);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
          text-decoration: none;
          font-variant-numeric: tabular-nums;
        }

        .tl-chip--accent {
          border-color: var(--tl-color-info-border);
          background: var(--tl-color-info-bg);
          color: var(--tl-color-info-text);
        }

        .tl-chip--info {
          border-color: var(--tl-color-info-border);
          background: var(--tl-color-info-bg);
          color: var(--tl-color-info-text);
        }

        .tl-chip--muted,
        .tl-chip--neutral {
          background: transparent;
          color: var(--tl-color-muted);
        }

        .tl-chip--warning {
          border-color: var(--tl-color-warning-border);
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
        }

        .tl-chip--danger {
          border-color: rgba(239, 68, 68, 0.28);
          background: var(--tl-color-danger-bg);
          color: var(--tl-color-danger);
        }

        .tl-chip--success {
          border-color: var(--tl-color-success-border);
          background: var(--tl-color-success-bg);
          color: var(--tl-color-success-text);
        }

        .tl-alert {
          margin: var(--tl-space-3) var(--tl-space-4);
          padding: var(--tl-space-3) var(--tl-space-4);
          border-radius: var(--tl-radius-md);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-alert--error {
          background: var(--tl-color-danger-bg);
          color: var(--tl-color-danger);
          border-left: 3px solid var(--tl-color-danger);
        }

        .tl-alert--info {
          background: var(--tl-color-surface);
          color: var(--tl-color-muted);
        }

        .tl-alert--warning {
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
          border-left: 3px solid var(--tl-color-warning-border);
        }

        .tl-empty {
          margin: var(--tl-space-4);
          padding: var(--tl-space-6);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface);
          color: var(--tl-color-muted);
          text-align: center;
          box-shadow: inset 0 0 0 1px var(--tl-color-border);
        }

        .tl-empty__title {
          margin: 0 0 var(--tl-space-1);
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
          text-wrap: balance;
        }

        .tl-empty__body {
          margin: 0;
          text-wrap: pretty;
        }

        .tl-empty--error {
          color: var(--tl-color-danger);
          background: var(--tl-color-danger-bg);
        }

        .tl-empty--never {
          background: var(--tl-color-surface-raised);
          border: 1px dashed var(--tl-color-border-strong);
        }

        .tl-status {
          padding: var(--tl-space-2) var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-variant-numeric: tabular-nums;
        }

        .tl-summary-grid {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: var(--tl-space-3);
          margin-bottom: var(--tl-space-4);
        }

        .tl-summary-card {
          display: grid;
          gap: var(--tl-space-1);
          min-width: 0;
          padding: var(--tl-space-3) var(--tl-space-4);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-summary-card--danger {
          box-shadow: inset 3px 0 0 var(--tl-color-danger), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-summary-card--warning {
          box-shadow: inset 3px 0 0 var(--tl-color-warning-border), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-summary-card__label {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-summary-card strong {
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-variant-numeric: tabular-nums;
        }

        .tl-viewport {
          max-height: 600px;
          overflow: auto;
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-change-list {
          display: block;
        }

        .tl-change {
          padding: var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          background: var(--tl-color-surface-raised);
        }

        .tl-change:last-child {
          border-bottom: none;
        }

        .tl-change__meta {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-change__op {
          display: inline-flex;
          align-items: center;
          min-height: 22px;
          padding: 1px var(--tl-space-2);
          border-radius: var(--tl-radius-pill);
          background: var(--tl-color-info-bg);
          color: var(--tl-color-accent-strong);
          font-weight: var(--tl-weight-strong);
          text-transform: uppercase;
        }

        .tl-change__summary {
          display: grid;
          grid-template-columns: minmax(160px, 1fr) minmax(220px, 1.5fr) auto;
          gap: var(--tl-space-3);
          align-items: center;
        }

        .tl-change__detail {
          min-width: 0;
        }

        .tl-change__actions {
          display: flex;
          justify-content: flex-end;
        }

        .tl-meta-row {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-meta-row code {
          color: var(--tl-color-text);
          font-variant-numeric: tabular-nums;
        }

        .tl-change__table,
        .tl-change__field,
        .tl-change__field-name {
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
        }

        .tl-change__table,
        .tl-change__field {
          border-radius: var(--tl-radius-sm);
          background: var(--tl-color-surface);
        }

        .tl-change__table {
          padding: 2px var(--tl-space-1);
          color: var(--tl-color-text);
        }

        .tl-change__time {
          font-variant-numeric: tabular-nums;
        }

        .tl-change__fields {
          display: flex;
          flex-direction: column;
          gap: var(--tl-space-1);
          margin-top: var(--tl-space-3);
        }

        .tl-change__field {
          padding: var(--tl-space-1) var(--tl-space-2);
          color: var(--tl-color-text);
        }

        .tl-change__field-name {
          font-weight: var(--tl-weight-strong);
        }

        .tl-change__before {
          color: var(--tl-color-danger);
          text-decoration: line-through;
        }

        .tl-change__omitted {
          color: var(--tl-color-muted);
          font-style: italic;
        }

        .tl-change__after {
          color: var(--tl-color-accent-strong);
        }

        .tl-transaction {
          padding: var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          margin-bottom: var(--tl-space-4);
        }

        .tl-transaction__title {
          margin: var(--tl-space-1) 0 0;
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
          text-wrap: balance;
        }

        .tl-table {
          width: 100%;
          border-collapse: collapse;
          background: var(--tl-color-surface-raised);
        }

        .tl-table-wrap {
          overflow-x: auto;
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-table-wrap .tl-table {
          min-width: 720px;
        }

        .tl-table th {
          padding: var(--tl-space-2) var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
          text-align: left;
        }

        .tl-table td {
          padding: var(--tl-space-2) var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          vertical-align: top;
        }

        .tl-table tr:last-child td {
          border-bottom: none;
        }

        .tl-table__code,
        .tl-table code {
          overflow-wrap: anywhere;
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
        }

        .tl-table__date,
        .tl-table__number {
          font-variant-numeric: tabular-nums;
          white-space: nowrap;
        }

        .tl-table__row--uncovered,
        .tl-table__row--failed {
          box-shadow: inset 3px 0 0 var(--tl-color-danger);
        }

        .tl-table__row--expected {
          background: var(--tl-color-surface);
          color: var(--tl-color-muted);
        }

        .tl-table__row--pending,
        .tl-table__row--running {
          box-shadow: inset 3px 0 0 var(--tl-color-info-text);
        }

        .tl-table__row--completed {
          box-shadow: inset 3px 0 0 var(--tl-color-success-text);
        }

        .tl-job-list {
          display: grid;
          gap: var(--tl-space-3);
          margin: var(--tl-space-4) 0;
        }

        .tl-job {
          display: grid;
          gap: var(--tl-space-3);
          padding: var(--tl-space-4);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job--danger {
          box-shadow: inset 3px 0 0 var(--tl-color-danger), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job--info {
          box-shadow: inset 3px 0 0 var(--tl-color-info-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job__main {
          display: grid;
          grid-template-columns: minmax(0, 1fr) auto;
          gap: var(--tl-space-3);
          align-items: start;
        }

        .tl-job__summary,
        .tl-job__actions {
          display: flex;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-job__summary {
          min-width: 0;
        }

        .tl-job__title {
          min-width: 0;
          display: grid;
          gap: 2px;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-job__title strong {
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
        }

        .tl-job__meta {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: var(--tl-space-2);
          margin: 0;
        }

        .tl-job__meta div {
          min-width: 0;
        }

        .tl-job__meta dt,
        .tl-param__key {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-job__meta dd {
          margin: 0;
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-variant-numeric: tabular-nums;
        }

        .tl-param-list {
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-space-2);
        }

        .tl-param {
          display: inline-flex;
          min-width: 0;
          max-width: 100%;
          align-items: baseline;
          gap: var(--tl-space-1);
          padding: 3px var(--tl-space-2);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface);
          color: var(--tl-color-text);
          box-shadow: var(--tl-shadow-border);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-param--muted {
          color: var(--tl-color-muted);
        }

        .tl-param__value {
          min-width: 0;
          overflow-wrap: anywhere;
          font-family: var(--tl-font-mono);
        }

        .tl-job__note {
          margin: 0;
          padding: var(--tl-space-2) var(--tl-space-3);
          border-radius: var(--tl-radius-md);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-job__note--error {
          background: var(--tl-color-danger-bg);
          color: var(--tl-color-danger);
        }

        .tl-section {
          margin-bottom: var(--tl-space-4);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          overflow: hidden;
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-section__header {
          padding: var(--tl-space-2) var(--tl-space-4);
          background: var(--tl-color-surface);
          border-bottom: 1px solid var(--tl-color-border);
        }

        .tl-section__title {
          margin: 0;
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          font-weight: var(--tl-weight-strong);
        }

        .tl-evidence__ref,
        .tl-evidence__meta code {
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
          font-size: var(--tl-font-size-label);
        }

        .tl-evidence__meta {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-policy__section--drift .tl-policy__section-header {
          border-left: 3px solid var(--tl-color-warning-border);
        }

        .tl-policy__section--introspect .tl-policy__section-header {
          border-left: 3px solid var(--tl-color-danger);
        }

        .tl-policy__section--match .tl-policy__section-header {
          border-left: 3px solid var(--tl-color-border-strong);
        }

        .tl-policy__empty {
          margin: 0;
          padding: var(--tl-space-4);
          color: var(--tl-color-muted);
        }

        .tl-policy__row {
          border-bottom: 1px solid var(--tl-color-border);
        }

        .tl-policy__row:last-child {
          border-bottom: 0;
        }

        .tl-policy__summary {
          padding: var(--tl-space-4);
          cursor: pointer;
          list-style: none;
          transition-property: background-color;
          transition-duration: var(--tl-transition-fast);
        }

        .tl-policy__summary:hover {
          background: var(--tl-color-surface);
        }

        .tl-policy__summary::-webkit-details-marker {
          display: none;
        }

        .tl-policy__row-main {
          display: flex;
          flex-wrap: wrap;
          align-items: baseline;
          gap: var(--tl-space-2);
          margin-bottom: var(--tl-space-1);
        }

        .tl-policy__table {
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
          font-weight: var(--tl-weight-strong);
        }

        .tl-policy__status,
        .tl-policy__hint {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-policy__hint,
        .tl-policy__warning {
          margin: 0;
        }

        .tl-policy__warning {
          margin-top: var(--tl-space-1);
          color: var(--tl-color-danger);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-policy__details {
          padding: 0 var(--tl-space-4) var(--tl-space-4);
        }

        .tl-subview {
          position: fixed;
          top: var(--tl-header-height);
          right: 0;
          bottom: 0;
          z-index: var(--tl-z-subview);
          width: min(760px, 100vw);
          overflow: auto;
          background: var(--tl-color-bg);
          box-shadow: var(--tl-shadow-raised);
        }

        .tl-subview[role="dialog"] {
          outline: none;
        }

        .tl-subview__header {
          position: sticky;
          top: 0;
          z-index: 1;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: var(--tl-space-3);
          padding: var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          background: rgba(255, 255, 255, 0.96);
          backdrop-filter: blur(8px);
        }

        .tl-subview__title {
          margin: 0;
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          font-weight: var(--tl-weight-strong);
          text-wrap: balance;
        }

        .tl-subview__content {
          display: grid;
          grid-template-columns: minmax(180px, 240px) minmax(0, 1fr);
          gap: var(--tl-space-4);
          padding: var(--tl-space-4);
        }

        .tl-subview__panel {
          min-width: 0;
        }

        .tl-subview__panel-title {
          margin: 0 0 var(--tl-space-2);
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          font-weight: var(--tl-weight-strong);
        }

        .tl-subview__timeline {
          margin: var(--tl-space-3) 0 0;
          padding: 0;
          list-style: none;
        }

        .tl-subview__timeline li {
          padding: var(--tl-space-2) 0;
          border-bottom: 1px solid var(--tl-color-border);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-kv {
          display: grid;
          gap: var(--tl-space-2);
          margin: 0;
        }

        .tl-kv__row {
          display: grid;
          grid-template-columns: minmax(120px, 180px) minmax(0, 1fr);
          gap: var(--tl-space-3);
          padding: var(--tl-space-2) 0;
          border-bottom: 1px solid var(--tl-color-border);
        }

        .tl-kv__key {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-kv__value {
          min-width: 0;
          overflow-wrap: anywhere;
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        @media (max-width: 720px) {
          .tl-toolbar {
            position: static;
          }

          .tl-toolbar__actions {
            justify-content: flex-start;
          }

          .tl-page__header {
            display: block;
          }

          .tl-subview__content {
            grid-template-columns: 1fr;
          }

          .tl-change__summary {
            grid-template-columns: 1fr;
          }

          .tl-job__main,
          .tl-job__meta,
          .tl-summary-grid {
            grid-template-columns: 1fr;
          }

          .tl-job__summary,
          .tl-job__actions {
            align-items: flex-start;
          }

          .tl-job__summary {
            flex-direction: column;
          }

          .tl-change__actions {
            justify-content: flex-start;
          }

          .tl-topbar {
            align-items: flex-start;
            flex-wrap: wrap;
          }

          .tl-topbar__status {
            width: 100%;
          }

          .tl-action-group--secondary {
            padding-left: 0;
            border-left: 0;
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .threadline-ui *,
          .threadline-ui *::before,
          .threadline-ui *::after {
            transition-duration: 1ms !important;
            animation-duration: 1ms !important;
            animation-iteration-count: 1 !important;
            scroll-behavior: auto !important;
          }

          .tl-button:active {
            transform: none;
          }
        }
      </style>
      """
    end
  end
end
