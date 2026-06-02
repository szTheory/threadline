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

          --tl-font-family: "Geist", "Inter", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          --tl-font-mono: "IBM Plex Mono", "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
          --tl-font-size-xs: 11px;
          --tl-font-size-sm: 12px;
          --tl-font-size-body: 14px;
          --tl-font-size-label: 12px;
          --tl-font-size-ui: 13px;
          --tl-font-size-heading: 18px;
          --tl-font-size-title: 22px;
          --tl-font-size-display: 28px;
          --tl-line-body: 1.5;
          --tl-line-label: 1.4;
          --tl-line-heading: 1.2;
          --tl-line-display: 1.15;
          --tl-weight-regular: 400;
          --tl-weight-medium: 500;
          --tl-weight-strong: 600;

          /* Brand: "night infrastructure with luminous signal lines" (Brand Book §10). */
          --tl-color-bg: #0B1020;
          /* Threadline Black */
          --tl-color-surface: #141B2D;
          /* Graphite */
          --tl-color-surface-raised: #1A2336;
          --tl-color-surface-tint: rgba(20, 27, 45, 0.92);
          --tl-color-surface-tint-strong: rgba(11, 16, 32, 0.96);
          --tl-color-backdrop: rgba(2, 4, 10, 0.62);
          --tl-color-border: #23304A;
          /* Slate Line */
          --tl-color-border-strong: #2E3D5C;
          --tl-color-text: #D7DEEA;
          /* Fog */
          --tl-color-muted: #8B98B0;
          /* Steel, lifted for AA on dark */
          --tl-color-accent: #4F8CFF;
          /* Thread Blue */
          --tl-color-accent-strong: #6FA1FF;
          --tl-color-accent-soft: rgba(79, 140, 255, 0.14);
          --tl-color-on-accent: #08101F;
          /* Dark ink for AA contrast on luminous accents */
          --tl-color-signal: #4EDFD1;
          /* Signal Cyan — correlation, live traces, positive system flow */
          --tl-color-signal-bg: rgba(78, 223, 209, 0.12);
          --tl-color-signal-border: rgba(78, 223, 209, 0.30);
          --tl-color-ink: #0F1728;
          --tl-color-paper: #F7F9FC;
          --tl-color-danger: #F06A6A;
          --tl-color-danger-bg: rgba(240, 106, 106, 0.13);
          --tl-color-warning-bg: rgba(243, 185, 76, 0.13);
          --tl-color-warning-text: #F3B94C;
          --tl-color-warning-border: rgba(243, 185, 76, 0.34);
          --tl-color-success-bg: rgba(63, 208, 143, 0.13);
          --tl-color-success-text: #3FD08F;
          --tl-color-success-border: rgba(63, 208, 143, 0.32);
          --tl-color-info-bg: rgba(79, 140, 255, 0.13);
          --tl-color-info-text: #7FA9FF;
          --tl-color-info-border: rgba(79, 140, 255, 0.32);
          --tl-color-neutral-bg: rgba(115, 129, 156, 0.12);
          --tl-color-neutral-text: #A3AFC2;
          --tl-color-neutral-border: #2E3D5C;
          --tl-color-op-insert-bg: rgba(63, 208, 143, 0.13);
          --tl-color-op-insert-text: #3FD08F;
          --tl-color-op-update-bg: rgba(79, 140, 255, 0.13);
          --tl-color-op-update-text: #7FA9FF;
          --tl-color-op-delete-bg: rgba(240, 106, 106, 0.13);
          --tl-color-op-delete-text: #F06A6A;
          --tl-color-brand-rail: #0B1020;

          --tl-radius-xs: 3px;
          --tl-radius-sm: 4px;
          --tl-radius-md: 6px;
          --tl-radius-lg: 8px;
          --tl-radius-xl: 12px;
          --tl-radius-pill: 999px;
          --tl-shadow-border: inset 0 0 0 1px var(--tl-color-border);
          --tl-shadow-subtle: 0 1px 2px rgba(2, 4, 10, 0.45), 0 1px 3px rgba(2, 4, 10, 0.30);
          --tl-shadow-popover: 0 10px 28px rgba(2, 4, 10, 0.55);
          --tl-shadow-raised: 0 18px 48px rgba(2, 4, 10, 0.66);
          --tl-z-base: 0;
          --tl-z-toolbar: 20;
          --tl-z-header: 30;
          --tl-z-popover: 40;
          --tl-z-subview: 50;
          --tl-z-toast: 60;
          --tl-header-height: 44px;
          --tl-header-height-mobile: 52px;
          --tl-control-height: 40px;
          --tl-control-height-compact: 32px;
          --tl-control-height-chip: 24px;
          --tl-control-height-badge: 22px;
          --tl-row-padding-compact: 10px;
          --tl-status-stripe-width: 3px;
          --tl-panel-padding: var(--tl-space-4);
          --tl-row-padding: var(--tl-space-3);
          --tl-table-min-width: 720px;
          --tl-drawer-width: 760px;
          --tl-viewport-max-height: 600px;
          --tl-muted-bg: var(--tl-color-surface);
          --tl-hit-area: 40px;
          --tl-focus-ring: 0 0 0 3px rgba(79, 140, 255, 0.38);
          --tl-gap-inline: var(--tl-space-2);
          --tl-gap-stack: var(--tl-space-4);
          --tl-pad-control: var(--tl-space-3);
          --tl-pad-panel: var(--tl-space-4);
          --tl-pad-page: var(--tl-space-6);
          --tl-motion-fast: 120ms;
          --tl-motion-base: 180ms;
          --tl-motion-slow: 240ms;
          --tl-motion-distance-sm: 8px;
          --tl-motion-distance-md: 16px;
          --tl-motion-stagger: 40ms;
          --tl-ease-standard: cubic-bezier(0.2, 0, 0, 1);
          --tl-ease-out: cubic-bezier(0.16, 1, 0.3, 1);
          --tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);

          min-height: 100%;
          color-scheme: dark;
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
          background: var(--tl-color-surface-tint);
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
          gap: var(--tl-space-2);
          min-width: 0;
          overflow-x: auto;
          scrollbar-width: none;
        }

        .tl-topbar__nav::-webkit-scrollbar {
          display: none;
        }

        .tl-topbar__nav-group {
          display: inline-flex;
          align-items: center;
          gap: var(--tl-space-1);
          min-width: max-content;
        }

        .tl-topbar__nav-group + .tl-topbar__nav-group {
          padding-left: var(--tl-space-2);
          border-left: 1px solid var(--tl-color-border);
        }

        .tl-topbar__nav-label {
          padding: 0 var(--tl-space-1);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-strong);
          text-transform: uppercase;
        }

        /* `.tl-topbar` prefix raises specificity above the scoped `.threadline-ui a`
           link color so inactive nav items read as muted tabs, not active links. */
        .tl-topbar .tl-topbar__nav-item {
          display: inline-flex;
          align-items: center;
          min-height: 32px;
          padding: var(--tl-space-1) var(--tl-space-3);
          border-radius: var(--tl-radius-md);
          color: var(--tl-color-muted);
          font-weight: var(--tl-weight-medium);
          text-decoration: none;
          white-space: nowrap;
          transition: color var(--tl-transition-fast), background-color var(--tl-transition-fast);
        }

        .tl-topbar .tl-topbar__nav-item:hover {
          background: var(--tl-color-surface);
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-topbar .tl-topbar__nav-item--active {
          background: var(--tl-color-accent-soft);
          color: var(--tl-color-accent-strong);
          font-weight: var(--tl-weight-strong);
          box-shadow: inset 0 0 0 1px var(--tl-color-info-border);
        }

        .tl-topbar__status .tl-chip {
          max-width: min(32ch, 32vw);
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .tl-topbar__status {
          display: flex;
          align-items: center;
          gap: var(--tl-space-2);
          white-space: nowrap;
        }

        .tl-topbar__stale {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-variant-numeric: tabular-nums;
        }

        .tl-page {
          padding: var(--tl-space-4);
        }

        .tl-page--intro {
          padding-bottom: 0;
        }

        /* Operator Home — task launcher (surface root). */
        .tl-home {
          max-width: 1000px;
          margin: 0 auto;
        }

        .tl-home__hero {
          padding: var(--tl-space-10) 0 var(--tl-space-6);
        }

        .tl-home__eyebrow {
          margin: 0 0 var(--tl-space-2);
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          letter-spacing: 0.16em;
          text-transform: uppercase;
          color: var(--tl-color-signal);
        }

        .tl-home__headline {
          margin: 0;
          font-size: var(--tl-font-size-display);
          line-height: var(--tl-line-display);
          font-weight: var(--tl-weight-medium);
          letter-spacing: -0.01em;
          color: var(--tl-color-text);
        }

        .tl-home__lede {
          margin: var(--tl-space-3) 0 0;
          max-width: 60ch;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
        }

        .tl-home__health {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          margin: var(--tl-space-5) 0 0;
        }

        .tl-home__health-label {
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          letter-spacing: 0.1em;
          text-transform: uppercase;
          color: var(--tl-color-muted);
        }

        .tl-home__cards {
          list-style: none;
          margin: 0;
          padding: 0;
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: var(--tl-space-4);
        }

        .tl-home__card {
          display: flex;
          flex-direction: column;
          align-items: flex-start;
          gap: var(--tl-space-3);
          padding: var(--tl-space-6);
          background: var(--tl-color-surface);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          box-shadow: var(--tl-shadow-subtle);
          animation: tl-rise-in var(--tl-motion-base) var(--tl-ease-out) both;
        }

        .tl-home__cards > .tl-home__card:nth-child(2) {
          animation-delay: var(--tl-motion-stagger);
        }

        .tl-home__cards > .tl-home__card:nth-child(3) {
          animation-delay: calc(var(--tl-motion-stagger) * 2);
        }

        .tl-home__card--primary {
          position: relative;
          overflow: hidden;
          grid-column: 1 / -1;
          background:
            linear-gradient(180deg, rgba(79, 140, 255, 0.07), rgba(79, 140, 255, 0) 64%),
            var(--tl-color-surface-raised);
          border-color: var(--tl-color-border-strong);
        }

        /* Signature: a Signal-Cyan "thread" draws across the top of the front door. */
        .tl-home__card--primary::before {
          content: "";
          position: absolute;
          inset: 0 0 auto 0;
          height: 2px;
          background: linear-gradient(90deg, var(--tl-color-signal), transparent 80%);
          transform: scaleX(0);
          transform-origin: left center;
          animation: tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both;
        }

        .tl-home__card-kicker {
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          letter-spacing: 0.12em;
          text-transform: uppercase;
          color: var(--tl-color-signal);
        }

        .tl-home__card-title {
          margin: 0;
          font-size: var(--tl-font-size-title);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-medium);
          color: var(--tl-color-text);
        }

        .tl-home__card-body {
          margin: 0;
          max-width: 58ch;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-ui);
          line-height: var(--tl-line-body);
        }

        .tl-home__card > .tl-button,
        .tl-home__card-links {
          margin-top: auto;
        }

        .tl-home__card-links {
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-space-2);
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

        .tl-orientation {
          display: grid;
          gap: var(--tl-space-3);
          padding: var(--tl-space-4);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: linear-gradient(180deg, var(--tl-color-surface-raised), var(--tl-color-surface));
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-orientation--investigation {
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-brand-rail);
        }

        .tl-orientation__header {
          display: flex;
          flex-wrap: wrap;
          align-items: flex-start;
          justify-content: space-between;
          gap: var(--tl-space-3);
        }

        .tl-orientation__title {
          margin: 0 0 var(--tl-space-1);
          font-size: var(--tl-font-size-title);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
        }

        .tl-orientation__lede {
          margin: 0;
          max-width: 68ch;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-ui);
          line-height: var(--tl-line-body);
        }

        .tl-orientation__actions {
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-space-2);
          justify-content: flex-end;
        }

        .tl-segmented {
          display: inline-flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-1);
          padding: var(--tl-space-1);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface);
        }

        .tl-segmented__item {
          min-height: var(--tl-control-height-compact);
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding: var(--tl-space-1) var(--tl-space-3);
          border: 0;
          border-radius: var(--tl-radius-md);
          background: transparent;
          color: var(--tl-color-muted);
          cursor: pointer;
          font: inherit;
          font-size: var(--tl-font-size-label);
          font-weight: var(--tl-weight-strong);
          text-decoration: none;
        }

        .tl-segmented__item:hover {
          background: var(--tl-color-surface-raised);
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-segmented__item.is-active {
          background: var(--tl-color-surface-raised);
          color: var(--tl-color-accent-strong);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-toolbar {
          position: sticky;
          top: var(--tl-header-height);
          z-index: var(--tl-z-toolbar);
          padding: var(--tl-space-4);
          background: var(--tl-color-surface-tint-strong);
          border-bottom: 1px solid var(--tl-color-border);
          box-shadow: 0 1px 0 rgba(2, 4, 10, 0.30);
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

        .tl-button:disabled,
        .tl-button[disabled],
        .tl-button[aria-disabled="true"] {
          opacity: 0.5;
          cursor: not-allowed;
          box-shadow: none;
          transform: none;
        }

        .tl-button:disabled:hover,
        .tl-button[disabled]:hover {
          box-shadow: none;
        }

        /* LiveView adds these in-flight (phx-disable-with / submitting). */
        .tl-button.phx-submit-loading,
        .tl-button.phx-click-loading,
        .tl-button[aria-busy="true"] {
          opacity: 0.7;
          cursor: progress;
        }

        .tl-button--compact {
          min-height: var(--tl-control-height-compact);
          padding: var(--tl-space-1) var(--tl-space-3);
        }

        .tl-button--quiet-primary {
          border-color: var(--tl-color-info-border);
          background: var(--tl-color-info-bg);
          color: var(--tl-color-accent-strong);
        }

        .tl-button--primary {
          background: var(--tl-color-accent);
          border-color: var(--tl-color-accent);
          color: var(--tl-color-on-accent);
        }

        .threadline-ui a.tl-button--primary {
          color: var(--tl-color-on-accent);
        }

        .tl-button--primary:hover {
          background: var(--tl-color-accent-strong);
          border-color: var(--tl-color-accent-strong);
          color: var(--tl-color-on-accent);
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

        .tl-button--primary.tl-button--danger {
          background: var(--tl-color-danger);
          border-color: var(--tl-color-danger);
          color: var(--tl-color-on-accent);
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
          min-height: var(--tl-control-height-chip);
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
          border-color: var(--tl-color-danger);
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

        .tl-empty__actions {
          display: flex;
          flex-wrap: wrap;
          justify-content: center;
          gap: var(--tl-space-2);
          margin-top: var(--tl-space-4);
        }

        .tl-empty--error {
          color: var(--tl-color-danger);
          background: var(--tl-color-danger-bg);
        }

        .tl-empty--never {
          background: var(--tl-color-surface-raised);
          border: 1px dashed var(--tl-color-border-strong);
        }

        .tl-empty--unsupported {
          background: linear-gradient(180deg, var(--tl-color-surface-raised), var(--tl-color-surface));
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

        .tl-summary-card--success {
          box-shadow: inset 3px 0 0 var(--tl-color-success-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-summary-card--info {
          box-shadow: inset 3px 0 0 var(--tl-color-info-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
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
          max-height: var(--tl-viewport-max-height);
          overflow: auto;
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-change-list {
          display: block;
          background: var(--tl-color-surface);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          overflow: hidden;
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-change {
          padding: var(--tl-space-4);
          border-bottom: 1px solid var(--tl-color-border);
          background: transparent;
          box-shadow: inset 3px 0 0 transparent;
          transition-property: background-color, box-shadow;
          transition-duration: var(--tl-transition-fast);
        }

        .tl-change:last-child {
          border-bottom: none;
        }

        .tl-change:hover {
          background: var(--tl-color-surface-raised);
        }

        .tl-change--insert {
          box-shadow: inset 3px 0 0 var(--tl-color-op-insert-text);
        }

        .tl-change--update {
          box-shadow: inset 3px 0 0 var(--tl-color-op-update-text);
        }

        .tl-change--delete {
          box-shadow: inset 3px 0 0 var(--tl-color-op-delete-text);
        }

        .tl-change--featured {
          border-top: 1px solid var(--tl-color-border);
          box-shadow: inset 3px 0 0 var(--tl-color-brand-rail), var(--tl-shadow-subtle);
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

        .tl-change__op--insert {
          background: var(--tl-color-op-insert-bg);
          color: var(--tl-color-op-insert-text);
        }

        .tl-change__op--update {
          background: var(--tl-color-op-update-bg);
          color: var(--tl-color-op-update-text);
        }

        .tl-change__op--delete {
          background: var(--tl-color-op-delete-bg);
          color: var(--tl-color-op-delete-text);
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
          flex-wrap: wrap;
          gap: var(--tl-space-2);
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

        .tl-transaction__breadcrumbs {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          margin-bottom: var(--tl-space-3);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-transaction__breadcrumbs span::before {
          content: "/";
          margin-right: var(--tl-space-2);
          color: var(--tl-color-border-strong);
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
          min-width: var(--tl-table-min-width);
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

        .tl-table--compact th,
        .tl-table--compact td {
          padding-top: var(--tl-row-padding-compact);
          padding-bottom: var(--tl-row-padding-compact);
        }

        .tl-table--sticky thead th {
          position: sticky;
          top: 0;
          z-index: 1;
          background: var(--tl-color-surface);
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

        .tl-table__row--covered {
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

        .tl-job--success {
          box-shadow: inset 3px 0 0 var(--tl-color-success-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
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
          gap: var(--tl-space-1);
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

        .tl-section--compact {
          margin-bottom: var(--tl-space-3);
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
          border-left: 3px solid var(--tl-color-warning-border);
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

        .tl-subview-backdrop {
          position: fixed;
          inset: var(--tl-header-height) 0 0;
          z-index: 49;
          background: var(--tl-color-backdrop);
          backdrop-filter: blur(1px);
        }

        .tl-subview {
          position: fixed;
          top: var(--tl-header-height);
          right: 0;
          bottom: 0;
          z-index: var(--tl-z-subview);
          width: min(var(--tl-drawer-width), 100vw);
          overflow: auto;
          background: var(--tl-color-bg);
          box-shadow: var(--tl-shadow-raised);
          animation: tl-drawer-in var(--tl-motion-base) var(--tl-ease-standard);
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
          background: var(--tl-color-surface-tint);
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

        @keyframes tl-drawer-in {
          from {
            opacity: 0;
            transform: translateX(16px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }

        @keyframes tl-rise-in {
          from {
            opacity: 0;
            transform: translateY(var(--tl-motion-distance-sm));
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        @keyframes tl-thread-draw {
          to {
            transform: scaleX(1);
          }
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

        .tl-page-band {
          display: grid;
          gap: var(--tl-space-3);
          margin-bottom: var(--tl-space-4);
        }

        .tl-journey-rail {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: var(--tl-space-2);
          margin-top: var(--tl-space-3);
        }

        .tl-journey-step {
          min-width: 0;
          padding: var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
        }

        .tl-journey-step__label {
          display: block;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-strong);
          line-height: var(--tl-line-label);
          text-transform: uppercase;
        }

        .tl-journey-step__title {
          display: block;
          margin-top: var(--tl-space-1);
          font-weight: var(--tl-weight-strong);
          line-height: var(--tl-line-label);
        }

        .tl-trust-rail {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          padding: var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface);
        }

        .tl-trust-rail__label {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
        }

        .tl-record-list {
          display: grid;
          gap: var(--tl-space-3);
        }

        .tl-record-card {
          display: grid;
          grid-template-columns: minmax(0, 1fr) auto;
          gap: var(--tl-space-3);
          padding: var(--tl-panel-padding);
          border: 1px solid var(--tl-color-border);
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-border-strong);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-record-card--success {
          border-left-color: var(--tl-color-success-text);
        }

        .tl-record-card--warning {
          border-left-color: var(--tl-color-warning-border);
        }

        .tl-record-card--danger {
          border-left-color: var(--tl-color-danger);
        }

        .tl-record-card--info {
          border-left-color: var(--tl-color-info-text);
        }

        .tl-record-card__main {
          min-width: 0;
          display: grid;
          gap: var(--tl-space-2);
        }

        .tl-record-card__title {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          margin: 0;
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          font-weight: var(--tl-weight-strong);
        }

        .tl-record-card__ref {
          min-width: 0;
          overflow-wrap: anywhere;
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-record-card__meta,
        .tl-record-card__actions {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-record-card__actions {
          justify-content: flex-end;
        }

        .tl-remediation {
          margin-bottom: var(--tl-space-4);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          overflow: hidden;
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-remediation__header {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          justify-content: space-between;
          gap: var(--tl-space-3);
          padding: var(--tl-space-3) var(--tl-space-4);
          background: var(--tl-color-surface);
          border-bottom: 1px solid var(--tl-color-border);
        }

        .tl-remediation__title {
          margin: 0;
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          font-weight: var(--tl-weight-strong);
        }

        .tl-remediation__body {
          padding: var(--tl-space-3) var(--tl-space-4);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-table--actionable tbody tr:hover {
          background: var(--tl-color-surface);
        }

        .tl-table__actions {
          white-space: nowrap;
        }

        .tl-policy__summary {
          position: relative;
          padding-left: calc(var(--tl-space-4) + 18px);
        }

        .tl-policy__summary::before {
          content: "";
          position: absolute;
          left: var(--tl-space-4);
          top: 21px;
          width: 8px;
          height: 8px;
          border-right: 2px solid var(--tl-color-muted);
          border-bottom: 2px solid var(--tl-color-muted);
          transform: rotate(-45deg);
          transition: transform var(--tl-transition-fast);
        }

        .tl-policy__row[open] .tl-policy__summary::before {
          transform: rotate(45deg);
        }

        .tl-policy__summary-actions {
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-space-2);
          margin-top: var(--tl-space-2);
        }

        .tl-policy__success {
          margin: 0 0 var(--tl-space-4);
          padding: var(--tl-space-3) var(--tl-space-4);
          border: 1px solid var(--tl-color-success-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-success-bg);
          color: var(--tl-color-success-text);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-evidence__ref,
        .tl-evidence__meta code,
        .tl-kv__value,
        .tl-policy__table {
          font-family: var(--tl-font-mono);
        }

        .tl-job__actions {
          min-width: min(220px, 100%);
        }

        .tl-job__source {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          justify-content: space-between;
          gap: var(--tl-space-2);
          padding-top: var(--tl-space-2);
          border-top: 1px solid var(--tl-color-border);
        }

        @media (max-width: 720px) {
          .tl-page {
            padding: var(--tl-space-3);
          }

          .tl-home__hero {
            padding: var(--tl-space-6) 0 var(--tl-space-4);
          }

          .tl-home__cards {
            grid-template-columns: 1fr;
          }

          .tl-home__card {
            padding: var(--tl-space-5);
          }

          .tl-orientation {
            padding: var(--tl-space-3);
          }

          .tl-orientation__actions {
            justify-content: flex-start;
          }

          .tl-toolbar {
            position: static;
            padding: var(--tl-space-3);
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
          .tl-summary-grid,
          .tl-journey-rail {
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
            min-height: var(--tl-header-height-mobile);
            align-items: center;
            flex-wrap: wrap;
            gap: var(--tl-space-2);
            padding: var(--tl-space-2) var(--tl-space-3);
          }

          .tl-topbar__nav {
            order: 2;
            flex-basis: auto;
          }

          .tl-topbar__nav-group + .tl-topbar__nav-group {
            padding-left: var(--tl-space-2);
          }

          .tl-topbar__status {
            order: 3;
            flex-basis: 100%;
            margin-left: 0;
          }

          .tl-topbar__nav-label {
            display: none;
          }

          .tl-topbar__status .tl-chip {
            max-width: 100%;
          }

          .tl-action-group--secondary {
            padding-left: 0;
            border-left: 0;
          }

          .tl-subview,
          .tl-subview-backdrop {
            top: 0;
            inset-block-start: 0;
          }

          .tl-subview {
            width: 100vw;
            min-height: 100dvh;
          }

          .tl-kv__row {
            grid-template-columns: 1fr;
            gap: var(--tl-space-1);
          }

          .tl-record-card,
          .tl-job__source {
            grid-template-columns: 1fr;
          }

          .tl-record-card {
            display: grid;
          }

          .tl-record-card__actions,
          .tl-job__source {
            justify-content: flex-start;
          }

          .tl-table-wrap .tl-table--responsive {
            min-width: 0;
          }

          .tl-table--responsive thead {
            display: none;
          }

          .tl-table--responsive,
          .tl-table--responsive tbody,
          .tl-table--responsive tr,
          .tl-table--responsive td {
            display: block;
            width: 100%;
          }

          .tl-table--responsive tr {
            padding: var(--tl-space-3);
            border-bottom: 1px solid var(--tl-color-border);
          }

          .tl-table--responsive td {
            display: grid;
            grid-template-columns: minmax(96px, 30%) minmax(0, 1fr);
            gap: var(--tl-space-2);
            padding: var(--tl-space-1) 0;
            border-bottom: 0;
          }

          .tl-table--responsive td::before {
            content: attr(data-label);
            color: var(--tl-color-muted);
            font-size: var(--tl-font-size-label);
            line-height: var(--tl-line-label);
            font-weight: var(--tl-weight-strong);
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
