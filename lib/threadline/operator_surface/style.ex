if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc """
    Provides isolated CSS for the Threadline Operator Surface.
    """

    import Phoenix.Component

    def css(assigns) do
      assigns =
        assign(
          assigns,
          :fonts_html,
          Phoenix.HTML.raw(font_face_style())
        )

      ~H"""
      {@fonts_html}<style>
        .threadline-ui {
          /* Phase 144 token freeze: this block is the source contract for the
             final v1.31 design-system catalog. */
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
          --tl-font-size-xs: 12px;
          --tl-font-size-sm: 13px;
          --tl-font-size-dense: 13px;
          --tl-font-size-body: 16px;
          --tl-font-size-label: 14px;
          --tl-font-size-ui: 15px;
          --tl-font-size-heading: 20px;
          --tl-font-size-title: 24px;
          --tl-font-size-display: 32px;
          --tl-line-body: 1.5;
          --tl-line-label: 1.4;
          --tl-line-heading: 1.2;
          --tl-line-display: 1.15;
          --tl-weight-regular: 400;
          --tl-weight-medium: 500;
          --tl-weight-strong: 600;
          /* Letter-spacing scale: caps labels track wider, display tracks tighter. */
          --tl-tracking-caps: 0.12em;
          --tl-tracking-caps-wide: 0.16em;
          --tl-tracking-tight: 0;


          /* Primitives */
          --tl-color-threadline-black: #0B1020;
          --tl-color-graphite: #141B2D;
          --tl-color-slate-line: #23304A;
          --tl-color-fog: #D7DEEA;
          --tl-color-paper: var(--tl-color-paper);
          --tl-color-mist: #E7ECF4;
          --tl-color-ink: var(--tl-color-ink);
          --tl-color-thread-blue: #4F8CFF;
          --tl-color-stitch-blue: #4781E6;
          --tl-color-signal-cyan: #4EDFD1;
          --tl-color-iris: #8A7CFF;
          --tl-color-ember: #FF8A5B;

          /* See DESIGN-SYSTEM.md § "Semantic Token Mapping" */
          /* Semantic UI Tokens */
          /* Brand: "night infrastructure with luminous signal lines" (Brand Book §10). */
          --tl-color-bg: var(--tl-color-threadline-black);
          /* Threadline Black */
          --tl-color-surface: var(--tl-color-graphite);
          /* Graphite */
          --tl-color-surface-raised: #1B253A;
          --tl-color-surface-hover: #202B42;
          --tl-color-surface-selected: #22304D;
          --tl-color-surface-tint: rgba(20, 27, 45, 0.94);
          --tl-color-surface-tint-strong: rgba(11, 16, 32, 0.96);
          --tl-color-backdrop: rgba(2, 4, 10, 0.62);
          --tl-color-border: var(--tl-color-slate-line);
          /* Slate Line */
          --tl-color-border-strong: #2E3D5C;
          --tl-color-border-focus: #7FA9FF;
          --tl-color-text: var(--tl-color-fog);
          /* Fog */
          --tl-color-muted: #A3AFC2;
          /* Steel, lifted for AA on dark */
          --tl-color-muted-soft: #8F9DB5;
          --tl-color-accent: var(--tl-color-thread-blue);
          /* Thread Blue */
          --tl-color-accent-strong: #6FA1FF;
          --tl-color-accent-soft: rgba(79, 140, 255, 0.18);
          --tl-color-accent-wash: rgba(79, 140, 255, 0.09);
          --tl-color-accent-border: rgba(127, 169, 255, 0.48);
          --tl-color-accent-inset: rgba(127, 169, 255, 0.16);
          /* Faint accent veil for raised front-door surfaces */
          --tl-color-on-accent: #08101F;
          /* Dark ink for AA contrast on luminous accents */
          --tl-color-signal: var(--tl-color-signal-cyan);
          /* Signal Cyan — correlation, live traces, positive system flow */
          --tl-color-signal-bg: rgba(78, 223, 209, 0.12);
          --tl-color-signal-border: rgba(78, 223, 209, 0.30);
          --tl-color-ink: var(--tl-color-ink);
          --tl-color-paper: var(--tl-color-paper);
          --tl-color-danger: #FF8585;
          --tl-color-danger-bg: rgba(240, 106, 106, 0.16);
          --tl-color-danger-border: rgba(255, 133, 133, 0.48);
          --tl-color-warning-bg: rgba(255, 209, 102, 0.10);
          --tl-color-warning-text: #F6C86B;
          --tl-color-warning-dot: #F6C86B;
          --tl-color-warning-border: rgba(246, 200, 107, 0.56);
          --tl-color-success-bg: rgba(63, 208, 143, 0.16);
          --tl-color-success-text: #5AE0A2;
          --tl-color-success-border: rgba(90, 224, 162, 0.44);
          --tl-color-info-bg: rgba(79, 140, 255, 0.16);
          --tl-color-info-text: #9AB9FF;
          --tl-color-info-border: rgba(127, 169, 255, 0.44);
          --tl-color-neutral-bg: rgba(115, 129, 156, 0.15);
          --tl-color-neutral-text: #B5C0D2;
          --tl-color-neutral-border: #2E3D5C;
          --tl-color-op-insert-bg: var(--tl-color-success-bg);
          --tl-color-op-insert-text: var(--tl-color-success-text);
          --tl-color-op-update-bg: var(--tl-color-info-bg);
          --tl-color-op-update-text: var(--tl-color-info-text);
          --tl-color-op-delete-bg: var(--tl-color-danger-bg);
          --tl-color-op-delete-text: var(--tl-color-danger);
          --tl-color-brand-rail: #0B1020;

          --tl-radius-xs: 3px;
          --tl-radius-sm: 4px;
          --tl-radius-md: 6px;
          --tl-radius-lg: 8px;
          --tl-radius-xl: 12px;
          --tl-radius-pill: 999px;
          --tl-shadow-border: inset 0 0 0 1px var(--tl-color-border);
          --tl-shadow-subtle: 0 1px 2px rgba(2, 4, 10, 0.50), 0 1px 3px rgba(2, 4, 10, 0.34);
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
          --tl-brand-logo-width: 132px;
          --tl-brand-logo-height: 32px;
          --tl-brand-logo-width-desktop: 148px;
          --tl-brand-logo-height-desktop: 36px;
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
          --tl-shell-gutter: var(--tl-space-4);
          --tl-viewport-max-height: 600px;
          /* Phase 142 breakpoint tokens document the accepted phone/tablet/desktop scale.
             CSS custom properties are not valid inside @media conditions, so media
             layers below keep standards-compliant literals governed by source tests. */
          --tl-breakpoint-phone-proof: 375px;
          --tl-breakpoint-tablet: 768px;
          --tl-breakpoint-desktop: 1280px;
          --tl-muted-bg: var(--tl-color-surface);
          --tl-hit-area: 40px;
          --tl-focus-ring: 0 0 0 3px rgba(127, 169, 255, 0.42), 0 0 0 1px var(--tl-color-border-focus);
          --tl-gap-inline: var(--tl-space-2);
          --tl-gap-stack: var(--tl-space-4);
          --tl-gap-section: var(--tl-space-8);
          --tl-pad-control: var(--tl-space-3);
          --tl-pad-panel: var(--tl-space-4);
          --tl-pad-page: var(--tl-space-4);
          --tl-motion-fast: 120ms;
          --tl-motion-base: 180ms;
          --tl-motion-slow: 240ms;
          --tl-motion-distance-sm: 8px;
          --tl-motion-distance-md: 16px;
          --tl-motion-stagger: 40ms;
          --tl-blur-panel: 8px;
          --tl-blur-veil: 1px;
          --tl-chevron-size: 8px;
          --tl-chevron-stroke: 2px;
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

        .threadline-ui[data-tl-theme="light"] {
          color-scheme: light;
          --tl-color-bg: #F7F9FC;
          --tl-color-surface: #FFFFFF;
          --tl-color-surface-raised: #EEF3FA;
          --tl-color-surface-hover: #E7ECF4;
          --tl-color-surface-selected: #DDE8FF;
          --tl-color-surface-tint: rgba(255, 255, 255, 0.92);
          --tl-color-surface-tint-strong: rgba(247, 249, 252, 0.96);
          --tl-color-backdrop: rgba(15, 23, 40, 0.42);
          --tl-color-border: #C9D3E2;
          --tl-color-border-strong: #A7B4C8;
          --tl-color-border-focus: #1557C0;
          --tl-color-text: #0F1728;
          --tl-color-muted: #3B4762;
          --tl-color-muted-soft: #73819C;
          --tl-color-accent: #1557C0;
          --tl-color-accent-strong: #0E459B;
          --tl-color-accent-soft: rgba(21, 87, 192, 0.12);
          --tl-color-accent-wash: rgba(21, 87, 192, 0.06);
          --tl-color-accent-border: rgba(21, 87, 192, 0.28);
          --tl-color-accent-inset: rgba(21, 87, 192, 0.16);
          --tl-color-on-accent: #FFFFFF;
          --tl-color-signal: #0F8F85;
          --tl-color-signal-bg: rgba(15, 143, 133, 0.12);
          --tl-color-signal-border: rgba(15, 143, 133, 0.30);
          --tl-color-ink: var(--tl-color-ink);
          --tl-color-paper: var(--tl-color-paper);
          --tl-color-danger: #A33434;
          --tl-color-danger-bg: rgba(163, 52, 52, 0.10);
          --tl-color-danger-border: rgba(163, 52, 52, 0.28);
          --tl-color-warning-bg: rgba(122, 84, 0, 0.12);
          --tl-color-warning-text: #8A5512;
          --tl-color-warning-dot: #CA8A04;
          --tl-color-warning-border: rgba(122, 84, 0, 0.30);
          --tl-color-success-bg: rgba(19, 108, 71, 0.12);
          --tl-color-success-text: #136C47;
          --tl-color-success-border: rgba(19, 108, 71, 0.30);
          --tl-color-info-bg: rgba(21, 87, 192, 0.10);
          --tl-color-info-text: #1557C0;
          --tl-color-info-border: rgba(21, 87, 192, 0.28);
          --tl-color-neutral-bg: rgba(59, 71, 98, 0.10);
          --tl-color-neutral-text: #3B4762;
          --tl-color-neutral-border: #C9D3E2;
          --tl-color-brand-rail: #0F1728;
          --tl-shadow-subtle: 0 1px 2px rgba(15, 23, 40, 0.08), 0 1px 3px rgba(15, 23, 40, 0.06);
          --tl-shadow-popover: 0 10px 28px rgba(15, 23, 40, 0.18);
          --tl-shadow-raised: 0 18px 48px rgba(15, 23, 40, 0.24);
          --tl-focus-ring: 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus);
        }

        @media (prefers-color-scheme: light) {
          .threadline-ui[data-tl-theme="system"] {
            color-scheme: light;
            --tl-color-bg: #F7F9FC;
            --tl-color-surface: #FFFFFF;
            --tl-color-surface-raised: #EEF3FA;
            --tl-color-surface-hover: #E7ECF4;
            --tl-color-surface-selected: #DDE8FF;
            --tl-color-surface-tint: rgba(255, 255, 255, 0.92);
            --tl-color-surface-tint-strong: rgba(247, 249, 252, 0.96);
            --tl-color-backdrop: rgba(15, 23, 40, 0.42);
            --tl-color-border: #C9D3E2;
            --tl-color-border-strong: #A7B4C8;
            --tl-color-border-focus: #1557C0;
            --tl-color-text: #0F1728;
            --tl-color-muted: #3B4762;
            --tl-color-muted-soft: #73819C;
            --tl-color-accent: #1557C0;
            --tl-color-accent-strong: #0E459B;
            --tl-color-accent-soft: rgba(21, 87, 192, 0.12);
            --tl-color-accent-wash: rgba(21, 87, 192, 0.06);
            --tl-color-accent-border: rgba(21, 87, 192, 0.28);
            --tl-color-accent-inset: rgba(21, 87, 192, 0.16);
            --tl-color-on-accent: #FFFFFF;
            --tl-color-signal: #0F8F85;
            --tl-color-signal-bg: rgba(15, 143, 133, 0.12);
            --tl-color-signal-border: rgba(15, 143, 133, 0.30);
            --tl-color-ink: var(--tl-color-ink);
            --tl-color-paper: var(--tl-color-paper);
            --tl-color-danger: #A33434;
            --tl-color-danger-bg: rgba(163, 52, 52, 0.10);
            --tl-color-danger-border: rgba(163, 52, 52, 0.28);
            --tl-color-warning-bg: rgba(122, 84, 0, 0.12);
            --tl-color-warning-text: #8A5512;
            --tl-color-warning-dot: #CA8A04;
            --tl-color-warning-border: rgba(122, 84, 0, 0.30);
            --tl-color-success-bg: rgba(19, 108, 71, 0.12);
            --tl-color-success-text: #136C47;
            --tl-color-success-border: rgba(19, 108, 71, 0.30);
            --tl-color-info-bg: rgba(21, 87, 192, 0.10);
            --tl-color-info-text: #1557C0;
            --tl-color-info-border: rgba(21, 87, 192, 0.28);
            --tl-color-neutral-bg: rgba(59, 71, 98, 0.10);
            --tl-color-neutral-text: #3B4762;
            --tl-color-neutral-border: #C9D3E2;
            --tl-color-brand-rail: #0F1728;
            --tl-shadow-subtle: 0 1px 2px rgba(15, 23, 40, 0.08), 0 1px 3px rgba(15, 23, 40, 0.06);
            --tl-shadow-popover: 0 10px 28px rgba(15, 23, 40, 0.18);
            --tl-shadow-raised: 0 18px 48px rgba(15, 23, 40, 0.24);
            --tl-focus-ring: 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus);
          }
        }

        /* Phase 167 (B): coverage table row hover polarity on light surfaces.
           The dark base keeps surface-raised default / surface hover (correct on
           dark, where raised is lighter than surface). On white that reads inverted
           (tinted default -> white hover), so the light and system lanes flip to a
           white default with a tinted hover. Additive only; the dark base rule and
           tokens are untouched. Row-to-row separation is preserved by the per-cell
           border-bottom (.tl-table td). */
        .threadline-ui[data-tl-theme="light"] .tl-table {
          background: var(--tl-color-surface);
        }

        .threadline-ui[data-tl-theme="light"] .tl-table--actionable tbody tr:hover {
          background: var(--tl-color-surface-hover);
        }

        @media (prefers-color-scheme: light) {
          .threadline-ui[data-tl-theme="system"] .tl-table {
            background: var(--tl-color-surface);
          }

          .threadline-ui[data-tl-theme="system"] .tl-table--actionable tbody tr:hover {
            background: var(--tl-color-surface-hover);
          }
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
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
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

        /* Skip-to-content link: visually hidden until focused, then the first
         * tab stop jumps keyboard / screen-reader users past the nav to <main>. */
        .tl-skip-link {
          position: absolute;
          left: var(--tl-space-2);
          top: calc(-1 * var(--tl-space-12));
          z-index: var(--tl-z-toast);
          padding: var(--tl-space-2) var(--tl-space-3);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-accent);
          color: var(--tl-color-on-accent);
          font-weight: var(--tl-weight-medium);
          text-decoration: none;
        }

        .tl-skip-link:focus {
          top: var(--tl-space-2);
        }

        .tl-sr-only {
          position: absolute;
          width: 1px;
          height: 1px;
          padding: 0;
          margin: -1px;
          overflow: hidden;
          clip: rect(0, 0, 0, 0);
          white-space: nowrap;
          border: 0;
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

        .threadline-ui {
          min-height: 100vh;
          /* svh keeps the shell exactly one viewport tall under mobile browser
             chrome; the 100vh line above is the fallback for older engines. */
          min-height: 100svh;
          /* Reconciled to the SAME token as .tl-target-row scroll-margin-top so a
             sticky topbar never covers an anchored row (offset isn't double-counted). */
          scroll-padding-top: calc(var(--tl-header-height-mobile) + var(--tl-space-4));
          /* Mobile nav/page is one scroll surface — keep scroll chaining out of it. */
          overscroll-behavior: contain;
        }

        .tl-topbar {
          position: sticky;
          top: 0;
          z-index: var(--tl-z-toast);
          min-height: var(--tl-header-height-mobile);
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          padding: var(--tl-space-2) var(--tl-space-3);
          background: var(--tl-color-surface-tint);
          border-bottom: 1px solid var(--tl-color-border);
          backdrop-filter: blur(var(--tl-blur-panel));
          font-size: var(--tl-font-size-label);
        }

        .tl-topbar__brand {
          display: inline-flex;
          align-items: center;
          flex: 0 0 auto;
          min-height: var(--tl-brand-logo-height);
          color: var(--tl-color-text);
          letter-spacing: 0;
          line-height: var(--tl-line-label);
          text-decoration: none;
          white-space: nowrap;
        }

        .threadline-ui a.tl-topbar__brand,
        .threadline-ui a.tl-topbar__brand:hover,
        .threadline-ui a.tl-topbar__brand:focus-visible {
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-topbar__brand:hover {
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-topbar__brand-logo {
          display: block;
          width: var(--tl-brand-logo-width);
          height: var(--tl-brand-logo-height);
          flex: 0 0 var(--tl-brand-logo-width);
          overflow: visible;
        }

        .tl-topbar__brand-wordmark {
          font-family: var(--tl-font-family);
          font-weight: var(--tl-weight-strong);
        }

        .tl-topbar__status .tl-chip {
          max-width: 100%;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .tl-topbar__status {
          display: flex;
          flex: 1 1 auto;
          align-items: center;
          justify-content: flex-end;
          gap: var(--tl-space-2);
          min-width: 0;
          white-space: nowrap;
        }

        .tl-topbar__stale {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-variant-numeric: tabular-nums;
        }

        .tl-shell-nav {
          position: sticky;
          top: var(--tl-header-height-mobile);
          z-index: calc(var(--tl-z-toast) - 1);
          background: var(--tl-color-surface-tint);
          border-bottom: 1px solid var(--tl-color-border);
          font-size: var(--tl-font-size-label);
        }

        .tl-shell-nav__toggle {
          display: flex;
          align-items: center;
          justify-content: space-between;
          width: 100%;
          min-height: var(--tl-hit-area);
          padding: var(--tl-space-2) var(--tl-space-3);
          border: 0;
          background: transparent;
          color: var(--tl-color-text);
          cursor: pointer;
          font: inherit;
          font-weight: var(--tl-weight-strong);
          list-style: none;
        }

        .tl-shell-nav__toggle::-webkit-details-marker {
          display: none;
        }

        .tl-shell-nav__toggle::after {
          content: "";
          width: var(--tl-chevron-size);
          height: var(--tl-chevron-size);
          border-right: var(--tl-chevron-stroke) solid var(--tl-color-muted);
          border-bottom: var(--tl-chevron-stroke) solid var(--tl-color-muted);
          transform: rotate(45deg);
          transition: transform var(--tl-transition-fast);
        }

        .tl-shell-nav[open] .tl-shell-nav__toggle::after {
          transform: rotate(225deg);
        }

        .tl-shell-nav__panel {
          display: none;
          gap: var(--tl-space-3);
          padding: 0 var(--tl-space-3) var(--tl-space-3);
          background: var(--tl-color-surface-tint);
          border-top: 1px solid var(--tl-color-border);
        }

        .tl-shell-nav[open] .tl-shell-nav__panel {
          display: grid;
        }

        .tl-shell-nav__toggle:focus-visible {
          outline: 2px solid var(--tl-color-focus);
          outline-offset: 2px;
        }

        .tl-shell-nav__group {
          display: grid;
          gap: var(--tl-space-1);
          min-width: 0;
        }

        .tl-theme-picker__form {
          display: grid;
          gap: var(--tl-space-2);
          padding: 0 var(--tl-space-1);
        }

        .tl-theme-picker__options {
          display: grid;
          gap: var(--tl-space-1);
          margin: 0;
          padding: 0;
          border: 0;
        }

        .tl-theme-picker__option {
          display: flex;
          align-items: center;
          gap: var(--tl-space-2);
          min-height: var(--tl-hit-area);
          padding: var(--tl-space-2) var(--tl-space-3);
          border: 1px solid transparent;
          border-radius: var(--tl-radius-md);
          color: var(--tl-color-muted);
          cursor: pointer;
          font-weight: var(--tl-weight-medium);
        }

        .tl-theme-picker__option:hover {
          background: var(--tl-color-surface-hover);
          border-color: var(--tl-color-border);
          color: var(--tl-color-text);
        }

        .tl-theme-picker__option:has(:checked) {
          background: var(--tl-color-accent-soft);
          box-shadow: inset 2px 0 0 var(--tl-color-accent-border);
          color: var(--tl-color-accent-strong);
          font-weight: var(--tl-weight-medium);
        }

        .tl-theme-picker__option:has(:focus-visible) {
          outline: 2px solid var(--tl-color-focus);
          outline-offset: 2px;
        }

        .tl-shell-nav__overview {
          display: grid;
          min-width: 0;
          padding-bottom: var(--tl-space-2);
          border-bottom: 1px solid var(--tl-color-border);
        }

        .tl-shell-nav__label {
          margin: 0;
          padding: var(--tl-space-2) var(--tl-space-1) var(--tl-space-1);
          color: var(--tl-color-muted);
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          letter-spacing: var(--tl-tracking-caps);
          line-height: var(--tl-line-label);
          text-transform: uppercase;
        }

        .threadline-ui .tl-shell-nav__item {
          display: flex;
          align-items: center;
          min-height: var(--tl-hit-area);
          padding: var(--tl-space-2) var(--tl-space-3);
          border: 1px solid transparent;
          border-radius: var(--tl-radius-md);
          color: var(--tl-color-muted);
          font-weight: var(--tl-weight-medium);
          text-decoration: none;
          transition: color var(--tl-transition-fast), background-color var(--tl-transition-fast), border-color var(--tl-transition-fast), box-shadow var(--tl-transition-fast);
        }

        .threadline-ui .tl-shell-nav__item:hover {
          background: var(--tl-color-surface-hover);
          border-color: var(--tl-color-border);
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .threadline-ui .tl-shell-nav__item--active,
        .threadline-ui .tl-shell-nav__item[aria-current="page"] {
          background: var(--tl-color-accent-soft);
          border-color: var(--tl-color-accent-border);
          box-shadow: inset 0 0 0 1px var(--tl-color-accent-inset);
          color: var(--tl-color-accent-strong);
          font-weight: var(--tl-weight-strong);
        }

        /* Phone-proof base: 375px acceptance viewport. Tablet and desktop layers
           progressively enhance below the keyframes. */
        .tl-container {
          max-width: 1000px;
          margin: 0 auto;
          justify-self: center;
        }

        .tl-page {
          padding: var(--tl-space-2);
        }

        .tl-page--intro {
          padding-bottom: 0;
        }

        /* Operator Home — task launcher (surface root). */
        .tl-home {
          max-width: 1000px;
          margin: 0 auto;
          justify-self: center;
        }

        .tl-home__hero {
          padding: var(--tl-space-6) 0 var(--tl-space-4);
        }

        .tl-home__headline {
          margin: 0;
          font-size: var(--tl-font-size-title);
          line-height: var(--tl-line-display);
          font-weight: var(--tl-weight-medium);
          letter-spacing: var(--tl-tracking-tight);
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
          letter-spacing: var(--tl-tracking-caps);
          text-transform: uppercase;
          color: var(--tl-color-muted);
        }

        .tl-home__cards {
          list-style: none;
          margin: 0;
          padding: 0;
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-4);
        }

        .tl-home__card {
          display: flex;
          flex-direction: column;
          align-items: flex-start;
          gap: var(--tl-space-3);
          padding: var(--tl-space-5);
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
            linear-gradient(180deg, var(--tl-color-accent-wash), transparent 64%),
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
          display: inline-flex;
          align-items: center;
          min-height: var(--tl-control-height-compact);
          padding: 0 var(--tl-space-2);
          border: 1px solid var(--tl-color-accent-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-accent-soft);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-strong);
          line-height: var(--tl-line-label);
          color: var(--tl-color-accent-strong);
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
          width: 100%;
          align-items: stretch;
        }

        .tl-home__prove-controls,
        .tl-home__prove-handoff {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-home__prove-handoff {
          padding-left: var(--tl-space-3);
          border-left: 1px solid var(--tl-color-border);
        }

        .tl-home__handoff-label {
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          letter-spacing: var(--tl-tracking-caps);
          text-transform: uppercase;
          color: var(--tl-color-muted);
        }

        .tl-home__resume {
          margin-top: var(--tl-space-6);
          display: grid;
          gap: var(--tl-space-1);
        }

        .tl-home__resume-empty {
          margin: 0;
          max-width: 56ch;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-ui);
          line-height: var(--tl-line-body);
        }

        .tl-home__section-title {
          margin: 0;
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
        }

        .tl-home__section-lede {
          margin: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-ui);
        }

        .tl-home__views {
          list-style: none;
          margin: var(--tl-space-2) 0 0;
          padding: 0;
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-space-2);
        }

        .tl-home__view {
          text-decoration: none;
        }

        .tl-home__earned-flow {
          margin-top: var(--tl-space-6);
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-3);
        }

        .tl-home__earned-panel {
          min-width: 0;
          display: grid;
          gap: var(--tl-space-3);
          padding: var(--tl-panel-padding);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-home__earned-copy {
          min-width: 0;
          display: grid;
          gap: var(--tl-space-1);
        }

        .tl-home__earned-form {
          min-width: 0;
          display: flex;
          flex-wrap: wrap;
          align-items: flex-end;
          gap: var(--tl-space-3);
        }

        .tl-home__earned-form .tl-button {
          flex: 0 0 auto;
        }

        .tl-home__earned-panel .tl-alert {
          margin: 0;
        }

        .tl-page__header {
          display: block;
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
          padding: var(--tl-space-3);
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
          justify-content: flex-start;
        }

        .tl-segmented-control,
        .tl-tabs {
          display: inline-flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-1);
          padding: var(--tl-space-1);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface);
        }

        .tl-segment {
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

        .tl-tab {
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

        .tl-segment:hover {
          background: var(--tl-color-surface-hover);
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-tab:hover {
          background: var(--tl-color-surface-hover);
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-segment[aria-pressed="true"] {
          background: var(--tl-color-accent-soft);
          color: var(--tl-color-accent-strong);
          box-shadow: inset 0 0 0 1px var(--tl-color-accent-border), var(--tl-shadow-subtle);
          font-weight: var(--tl-weight-strong);
        }

        .tl-tab[aria-selected="true"] {
          background: var(--tl-color-accent-soft);
          color: var(--tl-color-accent-strong);
          box-shadow: inset 0 0 0 1px var(--tl-color-accent-border), var(--tl-shadow-subtle);
          font-weight: var(--tl-weight-strong);
        }

        .tl-toolbar {
          position: static;
          top: var(--tl-header-height);
          z-index: var(--tl-z-toolbar);
          display: grid;
          gap: var(--tl-space-3);
          padding: var(--tl-space-3);
          background: var(--tl-color-surface-tint-strong);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
          backdrop-filter: blur(var(--tl-blur-panel));
        }

        .tl-timeline-command {
          gap: var(--tl-space-2);
          margin-bottom: var(--tl-space-4);
        }

        .tl-timeline-command__summary {
          display: grid;
          gap: var(--tl-space-2);
          align-items: start;
        }

        .tl-timeline-command__heading {
          display: grid;
          gap: var(--tl-space-1);
          min-width: 0;
        }

        .tl-timeline-command__title {
          margin: 0;
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-heading);
          font-weight: var(--tl-weight-strong);
          line-height: var(--tl-line-heading);
          letter-spacing: 0;
          text-wrap: balance;
        }

        .tl-timeline-command__lede {
          max-width: 68ch;
          margin: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-ui);
          line-height: var(--tl-line-body);
          text-wrap: pretty;
        }

        .tl-timeline-command__facts {
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-2);
          min-width: 0;
        }

        .tl-timeline-fact {
          display: grid;
          gap: var(--tl-space-1);
          min-width: 0;
          padding: var(--tl-space-2);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface-raised);
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-border-strong), var(--tl-shadow-border);
        }

        .tl-timeline-fact[data-status="info"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-info-text), var(--tl-shadow-border);
        }

        .tl-timeline-fact[data-status="warning"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-warning-border), var(--tl-shadow-border);
        }

        .tl-timeline-fact[data-status="success"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text), var(--tl-shadow-border);
        }

        .tl-timeline-fact__label {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          line-height: var(--tl-line-label);
          text-transform: uppercase;
          letter-spacing: var(--tl-tracking-caps);
        }

        .tl-timeline-fact__value {
          min-width: 0;
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-ui);
          font-weight: var(--tl-weight-strong);
          line-height: var(--tl-line-label);
          overflow-wrap: anywhere;
          font-variant-numeric: tabular-nums;
        }

        .tl-timeline-fact__detail {
          min-width: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          line-height: var(--tl-line-label);
          overflow-wrap: anywhere;
          font-variant-numeric: tabular-nums;
        }

        .tl-toolbar__form {
          display: grid;
          gap: var(--tl-space-3);
        }

        .tl-filter-group {
          display: grid;
          min-width: 0;
          margin: 0;
          padding: 0;
          border: 0;
          gap: var(--tl-space-2);
        }

        .tl-filter-group__legend {
          padding: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          line-height: var(--tl-line-label);
          text-transform: uppercase;
          letter-spacing: var(--tl-tracking-caps);
        }

        .tl-filter-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-3);
          align-items: start;
          min-width: 0;
        }

        .tl-toolbar__field {
          display: flex;
          width: 100%;
          min-width: 148px;
          flex-direction: column;
          gap: var(--tl-space-1);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-toolbar__control {
          width: 100%;
        }

        .tl-toolbar__field--wide {
          min-width: min(280px, 100%);
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
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-toolbar__control[type="datetime-local"],
        .tl-control[type="datetime-local"],
        .threadline-ui select.tl-toolbar__control,
        .threadline-ui select.tl-control {
          min-width: 178px;
        }

        .tl-toolbar__control:disabled,
        .tl-control:disabled {
          border-color: var(--tl-color-border);
          color: var(--tl-color-muted-soft);
          background: var(--tl-color-surface);
          cursor: not-allowed;
        }

        .tl-toolbar__control:hover:not(:disabled),
        .tl-control:hover:not(:disabled) {
          border-color: var(--tl-color-border-focus);
          background: var(--tl-color-surface-hover);
        }

        .tl-toolbar__control:focus,
        .tl-control:focus,
        .tl-toolbar__control:focus-visible,
        .tl-control:focus-visible {
          border-color: var(--tl-color-border-focus);
          background: var(--tl-color-surface-hover);
        }

        .tl-toolbar__hint,
        .tl-hint {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-toolbar__actions {
          display: flex;
          flex-wrap: wrap;
          align-items: flex-end;
          justify-content: flex-start;
          gap: var(--tl-space-2);
          min-width: 0;
        }

        .tl-filter-actions {
          align-self: end;
          padding-top: calc(var(--tl-font-size-label) * var(--tl-line-label) + var(--tl-space-1));
        }

        .tl-timeline-command .tl-filter-actions {
          padding-top: 0;
        }

        .tl-action-group {
          display: inline-flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-action-group--secondary {
          padding-left: 0;
          border-left: 0;
        }

        .tl-filter-disclosure {
          display: grid;
          gap: var(--tl-space-3);
          min-width: 0;
          padding-top: var(--tl-space-3);
          border-top: 1px solid var(--tl-color-border);
        }

        .tl-filter-disclosure__summary {
          min-height: var(--tl-control-height-compact);
          display: inline-flex;
          width: fit-content;
          align-items: center;
          gap: var(--tl-space-2);
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-label);
          font-weight: var(--tl-weight-medium);
          line-height: var(--tl-line-label);
          cursor: pointer;
          list-style: none;
        }

        .tl-filter-disclosure__summary::-webkit-details-marker {
          display: none;
        }

        .tl-filter-disclosure__summary::before {
          content: "";
          width: var(--tl-chevron-size);
          height: var(--tl-chevron-size);
          border-right: var(--tl-chevron-stroke) solid currentColor;
          border-bottom: var(--tl-chevron-stroke) solid currentColor;
          transform: rotate(-45deg);
          transition-property: transform;
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-filter-disclosure[open] > .tl-filter-disclosure__summary::before {
          transform: rotate(45deg);
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

        .tl-timeline-command__status {
          padding-top: var(--tl-space-1);
          border-top: 1px solid var(--tl-color-border);
        }

        .tl-timeline-command__utilities {
          display: grid;
          gap: var(--tl-space-3);
          padding-top: var(--tl-space-3);
          border-top: 1px solid var(--tl-color-border);
        }

        .tl-timeline-drawer {
          display: grid;
          align-content: start;
          gap: var(--tl-space-4);
        }

        .tl-timeline-drawer__header {
          display: flex;
          flex-wrap: wrap;
          align-items: start;
          justify-content: space-between;
          gap: var(--tl-space-3);
          padding-bottom: var(--tl-space-3);
          border-bottom: 1px solid var(--tl-color-border);
        }

        .tl-timeline-drawer__heading {
          display: grid;
          gap: var(--tl-space-1);
          min-width: 0;
        }

        .tl-timeline-drawer__section {
          display: grid;
          gap: var(--tl-space-3);
          min-width: 0;
        }

        .tl-timeline-drawer__section-heading {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        .tl-timeline-drawer__actions {
          padding-top: 0;
        }

        .tl-utility-group {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          min-width: 0;
        }

        .tl-utility-group__label {
          flex: 0 0 100%;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-medium);
          line-height: var(--tl-line-label);
          text-transform: uppercase;
          letter-spacing: var(--tl-tracking-caps);
        }

        .tl-saved-view-form {
          display: flex;
          flex: 1 1 320px;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          min-width: 0;
        }

        .tl-saved-view-form .tl-control {
          flex: 1 1 180px;
          min-width: min(220px, 100%);
        }

        .tl-button {
          min-height: var(--tl-hit-area);
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: var(--tl-space-2);
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
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-button__meta {
          display: inline-flex;
          min-width: 1.5em;
          min-height: 1.5em;
          align-items: center;
          justify-content: center;
          padding: 0 var(--tl-space-1);
          border-radius: 999px;
          background: var(--tl-color-accent-soft);
          color: var(--tl-color-accent-strong);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-strong);
          line-height: 1;
          font-variant-numeric: tabular-nums;
        }

        .threadline-ui a.tl-button,
        .threadline-ui a.tl-button:hover,
        .threadline-ui a.tl-button:focus-visible,
        .threadline-ui a.tl-chip,
        .threadline-ui a.tl-chip:hover,
        .threadline-ui a.tl-chip:focus-visible {
          text-decoration: none;
        }

        .tl-button:hover {
          border-color: var(--tl-color-border-strong);
          background: var(--tl-color-surface-hover);
          color: var(--tl-color-text);
          text-decoration: none;
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-button:active:not(:disabled):not([disabled]):not([aria-disabled="true"]) {
          transform: scale(0.96);
        }

        .tl-button.active:not(:disabled):not([disabled]):not([aria-disabled="true"]) {
          transform: scale(0.96);
        }

        .tl-button:disabled,
        .tl-button[disabled],
        .tl-button[aria-disabled="true"] {
          opacity: 1;
          border-color: var(--tl-color-border);
          background: var(--tl-color-surface);
          color: var(--tl-color-muted-soft);
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

        .threadline-ui a.tl-button--quiet-primary,
        .threadline-ui a.tl-button--quiet-primary:hover {
          color: var(--tl-color-accent-strong);
        }

        .tl-button--quiet-primary:hover {
          border-color: var(--tl-color-accent-border);
          background: var(--tl-color-accent-soft);
          color: var(--tl-color-accent-strong);
        }

        .tl-button--primary {
          background: var(--tl-color-accent);
          border-color: var(--tl-color-accent);
          color: var(--tl-color-on-accent);
        }

        .threadline-ui a.tl-button--primary,
        .threadline-ui a.tl-button--primary:hover {
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

        .threadline-ui a.tl-button--secondary,
        .threadline-ui a.tl-button--secondary:hover {
          color: var(--tl-color-text);
        }

        .tl-button--secondary:hover {
          border-color: var(--tl-color-border-focus);
        }

        .tl-button--ghost {
          border-color: transparent;
          background: transparent;
          color: var(--tl-color-muted);
        }

        .threadline-ui a.tl-button--ghost {
          color: var(--tl-color-muted);
        }

        .threadline-ui a.tl-button--ghost:hover {
          color: var(--tl-color-text);
        }

        .tl-button--ghost:hover {
          border-color: var(--tl-color-border);
          background: var(--tl-color-neutral-bg);
          color: var(--tl-color-text);
        }

        .tl-button--danger {
          color: var(--tl-color-danger);
        }

        .threadline-ui a.tl-button--danger,
        .threadline-ui a.tl-button--danger:hover {
          color: var(--tl-color-danger);
        }

        .tl-button--danger:hover {
          border-color: var(--tl-color-danger-border);
          background: var(--tl-color-danger-bg);
          color: var(--tl-color-danger);
        }

        .tl-button--primary.tl-button--danger {
          background: var(--tl-color-danger);
          border-color: var(--tl-color-danger-border);
          color: var(--tl-color-on-accent);
        }

        .tl-button--icon {
          width: var(--tl-hit-area);
          padding: 0;
          font-size: 16px;
        }

        .tl-icon {
          display: inline-block;
          width: 1em;
          height: 1em;
          flex: 0 0 auto;
          color: currentColor;
          fill: none;
          stroke: currentColor;
          stroke-linecap: round;
          stroke-linejoin: round;
          stroke-width: 2;
        }

        .tl-button__icon {
          width: 16px;
          height: 16px;
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

        .threadline-ui .tl-link:hover {
          text-decoration: underline;
        }

        .tl-chip {
          display: inline-flex;
          align-items: center;
          gap: var(--tl-space-1);
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

        /* Phase 167 — status chips: "signal node" treatment (cross-mode redesign).
           The status color lives in a single dot (--tl-chip-dot) plus a faint fill;
           the label text is neutral and readable. Replaces the prior tone-on-tone
           (status-colored text on a same-hue tint), which read muddy on white. Authored
           in the shared base rules so :dark and :light share one designed treatment —
           this intentionally retires the chip from the dark byte-stable freeze (167 D-09). */
        .tl-chip--info::before,
        .tl-chip--warning::before,
        .tl-chip--danger::before,
        .tl-chip--success::before {
          content: "";
          width: 6px;
          height: 6px;
          flex: 0 0 6px;
          border-radius: var(--tl-radius-pill);
          background: var(--tl-chip-dot);
        }

        .tl-chip--accent {
          color: var(--tl-color-text);
          --tl-chip-dot: var(--tl-color-info-text);
        }

        .tl-chip--info {
          color: var(--tl-color-text);
          --tl-chip-dot: var(--tl-color-info-text);
        }

        .tl-chip--muted,
        .tl-chip--neutral {
          border-color: var(--tl-color-neutral-border);
          background: var(--tl-color-neutral-bg);
          color: var(--tl-color-muted);
        }

        .tl-chip--warning {
          color: var(--tl-color-text);
          --tl-chip-dot: var(--tl-color-warning-dot);
        }

        .threadline-ui a.tl-chip--warning,
        .threadline-ui a.tl-chip--warning:hover,
        .threadline-ui a.tl-chip--warning:focus-visible {
          color: var(--tl-color-text);
        }

        .threadline-ui a.tl-chip--info,
        .threadline-ui a.tl-chip--info:hover,
        .threadline-ui a.tl-chip--info:focus-visible {
          color: var(--tl-color-text);
        }

        .threadline-ui a.tl-chip--accent,
        .threadline-ui a.tl-chip--accent:hover,
        .threadline-ui a.tl-chip--accent:focus-visible {
          color: var(--tl-color-text);
        }

        .threadline-ui a.tl-chip--muted,
        .threadline-ui a.tl-chip--muted:hover,
        .threadline-ui a.tl-chip--muted:focus-visible,
        .threadline-ui a.tl-chip--neutral,
        .threadline-ui a.tl-chip--neutral:hover,
        .threadline-ui a.tl-chip--neutral:focus-visible {
          color: var(--tl-color-muted);
        }

        .threadline-ui a.tl-chip--danger,
        .threadline-ui a.tl-chip--danger:hover,
        .threadline-ui a.tl-chip--danger:focus-visible {
          color: var(--tl-color-text);
        }

        .threadline-ui a.tl-chip--success,
        .threadline-ui a.tl-chip--success:hover,
        .threadline-ui a.tl-chip--success:focus-visible {
          color: var(--tl-color-text);
        }

        .threadline-ui a.tl-chip--accent:hover,
        .threadline-ui a.tl-chip--info:hover,
        .threadline-ui a.tl-chip--warning:hover,
        .threadline-ui a.tl-chip--danger:hover,
        .threadline-ui a.tl-chip--success:hover {
          text-decoration: underline;
        }

        .tl-chip--danger {
          color: var(--tl-color-text);
          --tl-chip-dot: var(--tl-color-danger);
        }

        .tl-chip--success {
          color: var(--tl-color-text);
          --tl-chip-dot: var(--tl-color-success-text);
        }

        .tl-alert {
          margin: var(--tl-space-3) var(--tl-space-4);
          padding: var(--tl-space-3) var(--tl-space-4);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-alert--error {
          background: var(--tl-color-danger-bg);
          color: var(--tl-color-danger);
          border-color: var(--tl-color-danger-border);
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-danger);
        }

        .tl-alert--info {
          background: var(--tl-color-info-bg);
          color: var(--tl-color-info-text);
          border-color: var(--tl-color-info-border);
        }

        .tl-alert--warning {
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
          border-color: var(--tl-color-warning-border);
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-warning-border);
        }

        .tl-alert--success {
          background: var(--tl-color-success-bg);
          color: var(--tl-color-success-text);
          border-color: var(--tl-color-success-border);
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-success-border);
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
          box-shadow: inset 0 0 0 1px var(--tl-color-danger-border);
        }

        .tl-empty--never {
          background: var(--tl-color-surface-raised);
          border: 1px dashed var(--tl-color-border-strong);
        }

        .tl-empty--unsupported {
          background: linear-gradient(180deg, var(--tl-color-surface-raised), var(--tl-color-surface));
        }

        .tl-stress {
          display: grid;
          gap: var(--tl-space-4);
          max-width: 1200px;
          margin: 0 auto;
        }

        .tl-stress__header {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
        }

        .tl-stress__metrics {
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-3);
        }

        .tl-stress__metric,
        .tl-stress__sidebar,
        .tl-stress__preview {
          min-width: 0;
          padding: var(--tl-space-4);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface);
          box-shadow: var(--tl-shadow-subtle);
        }

        .tl-stress__metric {
          display: grid;
          gap: var(--tl-space-1);
        }

        .tl-stress__metric-label {
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-xs);
          font-weight: var(--tl-weight-strong);
          letter-spacing: var(--tl-tracking-caps);
          text-transform: uppercase;
          color: var(--tl-color-muted);
        }

        .tl-stress__mono,
        .tl-stress__story-id,
        .tl-stress__story-fixture {
          font-family: var(--tl-font-mono);
          overflow-wrap: anywhere;
        }

        .tl-stress__layout {
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-4);
          align-items: start;
        }

        .tl-stress__sidebar,
        .tl-stress__preview,
        .tl-stress__story-list {
          display: grid;
          gap: var(--tl-space-3);
        }

        .tl-stress__category-nav,
        .tl-stress__filters {
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-space-2);
          align-items: center;
        }

        .tl-stress__category-link,
        .tl-stress__story-link {
          color: var(--tl-color-text);
          text-decoration: none;
        }

        .tl-stress__category-link {
          min-height: var(--tl-control-height-compact);
          display: inline-flex;
          align-items: center;
          padding: 0 var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface-raised);
          font-size: var(--tl-font-size-label);
        }

        .tl-stress__category-link:hover,
        .tl-stress__category-link:focus-visible,
        .tl-stress__category-link--active {
          border-color: var(--tl-color-accent-border);
          background: var(--tl-color-accent-soft);
          color: var(--tl-color-accent-strong);
        }

        .tl-stress__story-link {
          display: grid;
          gap: var(--tl-space-1);
          padding: var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface-raised);
          transition:
            border-color var(--tl-motion-fast) var(--tl-ease-out),
            background-color var(--tl-motion-fast) var(--tl-ease-out);
        }

        .tl-stress__story-link:hover,
        .tl-stress__story-link:focus-visible,
        .tl-stress__story-link--active {
          border-color: var(--tl-color-accent-border);
          background: var(--tl-color-accent-wash);
        }

        .tl-stress__story-meta,
        .tl-stress__story-fixture {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-sm);
        }

        .tl-stress__preview-header {
          display: flex;
          flex-wrap: wrap;
          align-items: flex-start;
          justify-content: space-between;
          gap: var(--tl-space-3);
        }

        .tl-stress__preview-title {
          margin: 0;
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
        }

        .tl-stress__ledger-table {
          display: grid;
          gap: var(--tl-space-2);
          margin: 0;
        }

        .tl-stress__ledger-table div {
          display: grid;
          gap: var(--tl-space-1);
          padding: var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface-raised);
        }

        .tl-stress__ledger-table dt {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-sm);
          font-weight: var(--tl-weight-strong);
        }

        .tl-stress__ledger-table dd {
          margin: 0;
        }

        .tl-stress__fixture-preview {
          padding: var(--tl-space-4);
          border: 1px dashed var(--tl-color-border-strong);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          color: var(--tl-color-text);
          line-height: var(--tl-line-body);
        }

        .tl-status {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          padding: var(--tl-space-2) 0 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-variant-numeric: tabular-nums;
        }

        .tl-status strong {
          color: var(--tl-color-text);
          font-weight: var(--tl-weight-medium);
        }

        /* De-emphasized pager (NAV-02): explicit Older/Newer controls + an honest
           role=status range caption over the existing keyset engine. Infinite scroll
           stays primary, so this sits quiet (secondary/compact buttons). Boundary
           controls are disabled, not hidden (D-18), so they read as visibly inactive
           (muted text, reduced opacity) rather than "disabled-looks-enabled". */
        .tl-pager {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          padding: var(--tl-space-3) 0 0;
        }

        .tl-pager__range {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-variant-numeric: tabular-nums;
        }

        .tl-pager__control[disabled],
        .threadline-ui button.tl-pager__control[disabled] {
          color: var(--tl-color-muted);
          opacity: 0.55;
          cursor: not-allowed;
        }

        .tl-summary-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-3);
          margin-bottom: var(--tl-space-4);
        }

        /* Canonical card primitive. New surfaces use `.tl-card` + slots; the older
           `.tl-summary-card` / `.tl-job` / `.tl-record-card` share its visual language
           (surface-raised, radius-lg, inset border + subtle shadow, optional status stripe). */
        .tl-card {
          display: grid;
          gap: var(--tl-space-3);
          min-width: 0;
          padding: var(--tl-panel-padding);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--danger {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--warning {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-warning-border), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--success {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--info {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-info-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--signal {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-signal), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card__header {
          display: flex;
          flex-wrap: wrap;
          align-items: baseline;
          justify-content: space-between;
          gap: var(--tl-space-2);
        }

        .tl-card__title {
          margin: 0;
          font-size: var(--tl-font-size-body);
          line-height: var(--tl-line-body);
          font-weight: var(--tl-weight-strong);
          text-wrap: balance;
        }

        .tl-card__meta {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-card__body {
          min-width: 0;
          margin: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-body);
        }

        .tl-card__actions {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
        }

        /*
         * Layout primitives (GROUP-01 / D-02) — stack/cluster own the group
         * spacing rhythm via flexbox `gap` over the semantic --tl-gap-* tokens.
         * No raw child margins: gap is the single source of inter-child spacing.
         */
        .tl-stack {
          display: flex;
          flex-direction: column;
          min-width: 0;
        }

        .tl-stack--tight {
          gap: var(--tl-space-1);
        }

        .tl-stack--inline {
          gap: var(--tl-gap-inline);
        }

        .tl-stack--stack {
          gap: var(--tl-gap-stack);
        }

        .tl-stack--section {
          gap: var(--tl-gap-section);
        }

        .tl-cluster {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-gap-inline);
          min-width: 0;
        }

        .tl-cluster--start {
          justify-content: flex-start;
        }

        .tl-cluster--between {
          justify-content: space-between;
        }

        .tl-cluster--end {
          justify-content: flex-end;
        }

        /*
         * data_panel — the state-coordinating shell (D-03 / D-06). Flat page-stack
         * section: ONE card boundary per logical unit (D-176-11), so the panel itself
         * is NOT wrapped in a card. Inner rhythm uses the semantic gap tokens.
         */
        .tl-data-panel {
          display: flex;
          flex-direction: column;
          gap: var(--tl-gap-stack);
          min-width: 0;
        }

        /*
         * The data region cross-fades on a state swap (happy <-> loading <-> empty <->
         * error). A `transition` can't fire here — data_panel swaps states by rendering
         * different child markup, never by toggling the region's own opacity, so the
         * value never changes. We use an opacity-in `animation` instead: when the caller
         * supplies an id, the region's id is state-keyed (`{id}-region-{state}`), so a
         * state swap makes LiveView replace the element and the fade replays; within :ok
         * the id is stable so streamed <tr> updates do NOT re-trigger it (D-11). Opacity-
         * only so it degrades cleanly; the reduced-motion blanket collapses it near-
         * instantly (D-12), no per-component handling.
         */
        .tl-data-panel__region {
          animation: tl-fade-in var(--tl-motion-fast) var(--tl-ease-standard);
          min-width: 0;
        }

        .tl-data-panel__pager {
          min-width: 0;
        }

        /*
         * toolbar — search/filter/sort row (D-06). Built on the cluster mechanism so it
         * wraps at narrow widths (D-13). `is-disabled` is the AFFORDANCE (pointer-events
         * off + dimming); the page also sets the HTML `disabled` attr on the real
         * controls for enforcement (Pitfall 6). The reduced-motion blanket needs no
         * special handling here (no motion).
         */
        .tl-toolbar {
          gap: var(--tl-gap-inline);
        }

        .tl-toolbar.is-disabled {
          pointer-events: none;
          opacity: 0.55;
        }

        /*
         * detail_header — title + metadata kv + actions (D-03). Rhythm: <h2> title,
         * actions clustered to the trailing edge on the same top row, kv metadata a
         * --tl-space-6 break below.
         */
        .tl-detail-header {
          display: flex;
          flex-direction: column;
          gap: var(--tl-space-6);
          min-width: 0;
        }

        .tl-detail-header__top {
          display: flex;
          flex-wrap: wrap;
          align-items: flex-start;
          justify-content: space-between;
          gap: var(--tl-gap-inline);
          min-width: 0;
        }

        .tl-detail-header__title {
          margin: 0;
          font-size: var(--tl-font-size-title);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
          text-wrap: balance;
          min-width: 0;
        }

        .tl-detail-header__actions {
          flex: 0 0 auto;
        }

        /*
         * Metric card — the compact "label + big number" summary tile.
         * Canonical density variant of the card; status via [data-status]
         * (the shared stripe contract). Self-sufficient: used standalone as
         * .tl-card--metric (not composed with .tl-card) so its dense padding
         * is not overridden by the full card's slot layout.
         */
        .tl-card--metric {
          display: grid;
          gap: var(--tl-space-1);
          min-width: 0;
          padding: var(--tl-space-3) var(--tl-space-4);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--metric[data-status="danger"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--metric[data-status="warning"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-warning-border), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--metric[data-status="success"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card--metric[data-status="info"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-info-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-card__metric-label {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-card__metric {
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
          box-shadow: inset var(--tl-status-stripe-width) 0 0 transparent;
          transition-property: background-color, box-shadow;
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-change:last-child {
          border-bottom: none;
        }

        .tl-change:hover {
          background: var(--tl-color-surface-raised);
        }

        .tl-change--insert {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-op-insert-text);
        }

        .tl-change--update {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-op-update-text);
        }

        .tl-change--delete {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-op-delete-text);
        }

        .tl-change--featured {
          border-top: 1px solid var(--tl-color-border);
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-brand-rail), var(--tl-shadow-subtle);
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
          min-height: var(--tl-control-height-badge);
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
          grid-template-columns: 1fr;
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
          justify-content: flex-start;
        }

        /* Canonical metadata row. */
        .tl-meta {
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

        /*
         * Narrow-viewport truncation (D-13, Pitfall 5): the current/last crumb (the
         * location label, which can be a long table/correlation name) ellipsis-clips so
         * the header never forces horizontal scroll at 320px. Ancestor crumbs stay
         * links and wrap via the trail's flex-wrap.
         */
        .tl-transaction__breadcrumbs-current {
          display: inline-block;
          max-width: clamp(12ch, 50vw, 40ch);
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
          vertical-align: bottom;
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
          font-size: var(--tl-font-size-dense);
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

        .tl-table--compact .tl-table__code,
        .tl-table--compact code {
          font-size: var(--tl-font-size-dense);
        }

        .tl-table__date,
        .tl-table__number {
          font-variant-numeric: tabular-nums;
          white-space: nowrap;
        }

        .tl-table__row--uncovered,
        .tl-table__row--failed {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger);
        }

        .tl-table__row--expected {
          background: var(--tl-color-surface);
          color: var(--tl-color-muted);
        }

        .tl-table__row--pending,
        .tl-table__row--running {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-info-text);
        }

        .tl-table__row--completed {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text);
        }

        .tl-table__row--covered {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text);
        }

        /* Status-driven stripe: map a row's state to a status once in markup
           (data-status) and new states need zero new CSS. */
        .tl-table tr[data-status="danger"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger);
        }

        .tl-table tr[data-status="warning"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-warning-border);
        }

        .tl-table tr[data-status="success"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text);
        }

        .tl-table tr[data-status="info"] {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-info-text);
        }

        .tl-table tr[data-status="neutral"] {
          background: var(--tl-color-surface);
          color: var(--tl-color-muted);
        }

        .tl-job-list {
          display: grid;
          gap: var(--tl-space-3);
          margin: var(--tl-space-4) 0;
        }

        .tl-job-group {
          display: grid;
          gap: var(--tl-space-3);
          margin: var(--tl-space-4) 0;
          padding: var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface);
        }

        .tl-job-group__header {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          justify-content: space-between;
          gap: var(--tl-space-2);
          min-width: 0;
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-job-group__title {
          margin: 0;
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-heading);
          line-height: var(--tl-line-heading);
          font-weight: var(--tl-weight-strong);
        }

        .tl-secondary-ref {
          min-width: 0;
          max-width: 100%;
          overflow: hidden;
          color: var(--tl-color-muted);
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          overflow-wrap: anywhere;
        }

        .tl-target-row {
          scroll-margin-top: calc(var(--tl-header-height-mobile) + var(--tl-space-4));
        }

        .tl-target-row:target {
          background: var(--tl-color-surface-raised);
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger), var(--tl-shadow-border);
        }

        /* Find cluster primitives: shared value, diff, filter, actor, and remediation seams. */
        .tl-value {
          display: inline;
          min-width: 0;
          color: var(--tl-color-text);
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          overflow-wrap: anywhere;
          font-variant-numeric: tabular-nums;
        }

        .tl-value--null,
        .tl-value--omitted,
        .tl-value--absent {
          color: var(--tl-color-muted-soft);
          font-style: italic;
        }

        .tl-value--time {
          color: var(--tl-color-signal);
        }

        .tl-value--redacted {
          border-radius: var(--tl-radius-sm);
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
          padding: 0 var(--tl-space-1);
        }

        .tl-value--json {
          color: var(--tl-color-neutral-text);
        }

        .tl-value--primitive {
          color: var(--tl-color-info-text);
        }

        .tl-diff {
          display: grid;
          gap: var(--tl-space-2);
          padding: var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface);
        }

        .tl-diff__row {
          display: grid;
          gap: var(--tl-space-2);
          min-width: 0;
        }

        .tl-diff__cell {
          display: inline-flex;
          align-items: center;
          gap: var(--tl-space-2);
          min-width: 0;
          flex-wrap: wrap;
        }

        .tl-diff__arrow {
          color: var(--tl-color-muted);
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-filter-summary {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: var(--tl-space-2);
          padding-top: var(--tl-space-2);
          border-top: 1px solid var(--tl-color-border);
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-filter-summary > strong {
          color: var(--tl-color-text);
          font-weight: var(--tl-weight-medium);
        }

        .tl-filter-summary__window {
          min-width: 0;
          overflow-wrap: anywhere;
          font-variant-numeric: tabular-nums;
        }

        .tl-filter-summary__empty {
          color: var(--tl-color-muted);
        }

        .tl-journey--legend {
          padding: var(--tl-space-2) 0;
          border: 0;
          background: transparent;
          box-shadow: none;
          color: var(--tl-color-muted);
        }

        .tl-actor-summary {
          display: inline-flex;
          align-items: center;
          min-width: 0;
          gap: var(--tl-space-2);
          color: var(--tl-color-text);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-medium);
        }

        .tl-remediation {
          display: grid;
          gap: var(--tl-space-2);
        }

        .tl-remediation__command {
          display: inline-flex;
          align-items: center;
          max-width: 100%;
          min-height: var(--tl-control-height-compact);
          padding: var(--tl-space-1) var(--tl-space-2);
          border: 1px solid var(--tl-color-warning-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          overflow-wrap: anywhere;
        }

        .tl-remediation__action {
          display: inline-flex;
          align-items: center;
          min-height: var(--tl-control-height-compact);
          color: var(--tl-color-accent);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
        }

        .tl-coverage-actions {
          display: grid;
          gap: var(--tl-space-2);
          justify-items: start;
          min-width: 0;
          max-width: 100%;
          white-space: normal;
        }

        .tl-row-action {
          display: grid;
          gap: var(--tl-space-2);
          min-width: 0;
          max-width: 100%;
        }

        .tl-row-action__summary {
          display: inline-flex;
          align-items: center;
          gap: var(--tl-space-2);
          min-height: var(--tl-hit-area);
          width: fit-content;
          padding: var(--tl-space-1) var(--tl-space-3);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface);
          color: var(--tl-color-accent-strong);
          cursor: pointer;
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
          list-style: none;
          transition-property: color, background-color, border-color, box-shadow;
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-row-action__summary::-webkit-details-marker {
          display: none;
        }

        .tl-row-action__summary::marker {
          content: "";
        }

        .tl-row-action__summary:hover {
          border-color: var(--tl-color-border-focus);
          background: var(--tl-color-surface-hover);
          color: var(--tl-color-text);
        }

        .tl-row-action[open] > .tl-row-action__summary {
          border-color: var(--tl-color-warning-border);
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
        }

        .tl-row-action__body {
          display: grid;
          gap: var(--tl-space-2);
          min-width: 0;
          max-width: 100%;
          padding: var(--tl-space-2);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          background: var(--tl-color-surface);
        }

        .tl-command-copy {
          display: grid;
          grid-template-columns: minmax(0, 1fr) auto;
          align-items: start;
          gap: var(--tl-space-2);
          min-width: 0;
          max-width: 100%;
        }

        .tl-row-action__hint {
          min-width: 0;
          overflow-wrap: anywhere;
          white-space: normal;
        }

        .tl-copy--command {
          min-height: var(--tl-control-height-compact);
        }

        .tl-short-content {
          max-width: 72ch;
          margin-inline: auto;
        }
        /* End Find cluster primitives */

        .tl-job {
          display: grid;
          gap: var(--tl-space-3);
          padding: var(--tl-space-4);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-surface-raised);
          box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job--danger {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job--info {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-info-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job--success {
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text), var(--tl-shadow-border), var(--tl-shadow-subtle);
        }

        .tl-job__main {
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-3);
          align-items: start;
        }

        .tl-job__summary,
        .tl-job__actions {
          display: flex;
          align-items: flex-start;
          gap: var(--tl-space-2);
        }

        .tl-job__summary {
          min-width: 0;
          flex-direction: column;
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
          grid-template-columns: 1fr;
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
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
        }

        .tl-evidence__meta {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-policy__section--drift .tl-policy__section-header {
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-warning-border);
        }

        .tl-policy__section--introspect .tl-policy__section-header {
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-warning-border);
        }

        .tl-policy__section--match .tl-policy__section-header {
          border-left: var(--tl-status-stripe-width) solid var(--tl-color-border-strong);
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
          transition-duration: var(--tl-motion-fast);
          transition-timing-function: var(--tl-ease-standard);
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
          font-family: var(--tl-font-mono);
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

        /* Spotlight the diverging configured/deployed cells in a drift row. */
        .tl-policy__cell--drift {
          background: var(--tl-color-warning-bg);
          color: var(--tl-color-warning-text);
          font-weight: var(--tl-weight-strong);
          box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-warning-border);
        }

        /* Expand the configured-vs-deployed detail instead of snapping it open.
           Progressive enhancement: browsers without ::details-content just snap,
           and the reduced-motion block below neutralises the transition. */
        .tl-policy__row {
          interpolate-size: allow-keywords;
        }

        .tl-policy__row::details-content {
          block-size: 0;
          overflow: clip;
          opacity: 0;
          transition: opacity var(--tl-motion-base) var(--tl-ease-out);
        }

        .tl-policy__row[open]::details-content {
          block-size: auto;
          opacity: 1;
        }

        .tl-subview-backdrop {
          position: fixed;
          inset: 0;
          z-index: 49;
          background: var(--tl-color-backdrop);
          backdrop-filter: blur(var(--tl-blur-veil));
        }

        .tl-subview {
          position: fixed;
          top: 0;
          right: 0;
          bottom: 0;
          z-index: var(--tl-z-subview);
          width: 100vw;
          min-height: 100vh;
          min-height: 100dvh;
          overflow: auto;
          overscroll-behavior: contain;
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
          backdrop-filter: blur(var(--tl-blur-panel));
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
          grid-template-columns: 1fr;
          gap: var(--tl-space-4);
          padding: var(--tl-space-4);
        }

        @keyframes tl-drawer-in {
          from {
            opacity: 0;
            transform: translateX(var(--tl-motion-distance-md));
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

        @keyframes tl-fade-in {
          from {
            opacity: 0;
          }
        }

        /*
         * Overlay JS-transition utility classes (D-10.1, RESEARCH Pitfall 2).
         * modal/drawer/toast (ui.ex) drive enter/exit via Phoenix.LiveView.JS
         * show/hide `transition:` tuples {transition_classes, from, to}. The
         * transition class sets the tokenized transition-property; the from/to
         * classes set the start/end opacity/transform. These are CLASS SELECTORS
         * (NOT the same-named @keyframes, which drive CSS `animation:` mount
         * reveals) — defining them here makes the overlay motion real instead of
         * an instant snap. GPU-only (opacity/transform); the reduced-motion
         * blanket below collapses the transition near-instantly (D-12), so no
         * per-component prefers-reduced-motion handling is needed. Every JS.show/
         * hide passes an explicit time matching --tl-motion-base so the token
         * stays the single source of truth (D-11, Pitfall 3).
         */
        .tl-fade-in,
        .tl-fade-out {
          transition: opacity var(--tl-motion-base) var(--tl-ease-standard);
        }

        .tl-rise-in,
        .tl-rise-out {
          transition:
            opacity var(--tl-motion-base) var(--tl-ease-standard),
            transform var(--tl-motion-base) var(--tl-ease-standard);
        }

        .tl-slide-in-right,
        .tl-slide-out-right {
          transition: transform var(--tl-motion-base) var(--tl-ease-standard);
        }

        .opacity-0 {
          opacity: 0;
        }

        .opacity-100 {
          opacity: 1;
        }

        .translate-y-0 {
          transform: translateY(0);
        }

        .translate-y-4 {
          transform: translateY(var(--tl-motion-distance-md));
        }

        .translate-x-0 {
          transform: translateX(0);
        }

        .translate-x-full {
          transform: translateX(100%);
        }

        /* `.hidden` backs the modal/drawer `if(!@show, do: "hidden")` toggle. */
        .hidden {
          display: none;
        }

        /*
         * Overlay shells. The *-container is the full-viewport positioning layer
         * the JS show/hide targets (#id); the scrim is the dimmed backdrop and the
         * wrapper centers/edges the dialog. Opacity/transform stay on the JS
         * utility classes above so the container itself only owns layout + stacking.
         */
        .tl-modal-container,
        .tl-drawer-container {
          position: fixed;
          inset: 0;
          z-index: var(--tl-z-subview);
        }

        .tl-modal-scrim,
        .tl-drawer-scrim {
          position: absolute;
          inset: 0;
          background: var(--tl-color-scrim, rgba(7, 11, 20, 0.62));
        }

        .tl-modal-wrapper {
          position: relative;
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: 100%;
          padding: var(--tl-space-4);
        }

        .tl-modal {
          position: relative;
          width: min(var(--tl-modal-width, 560px), 100%);
          max-height: calc(100% - var(--tl-space-8));
          overflow: auto;
          padding: var(--tl-space-5);
          background: var(--tl-color-surface-raised);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          transform-origin: top center;
          transition-property: opacity, transform;
          transition-duration: var(--tl-motion-base);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-drawer-wrapper {
          position: absolute;
          inset: 0 0 0 auto;
          display: flex;
        }

        .tl-drawer {
          position: relative;
          width: min(var(--tl-drawer-width), 100vw);
          height: 100%;
          overflow: auto;
          padding: var(--tl-space-5);
          background: var(--tl-color-surface-raised);
          border-left: 1px solid var(--tl-color-border);
          transform-origin: top right;
          transition-property: opacity, transform;
          transition-duration: var(--tl-motion-base);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-popover,
        .tl-shadow-popover,
        .tl-accordion__panel {
          transform-origin: top right;
          transition-property: opacity, transform;
          transition-duration: var(--tl-motion-base);
          transition-timing-function: var(--tl-ease-standard);
        }

        .tl-accordion__panel {
          transform-origin: top center;
        }

        /*
         * toast — fade-up entrance (Open Question 3) via a phx-mounted JS.show
         * using the same .tl-fade-in/.opacity-* utilities + explicit time. Manual/
         * phx-click dismiss only (auto-dismiss is out of scope). Warning/info/etc.
         * tinting rides the per-kind --tl-color-* tokens already in the catalog.
         */
        .tl-toast {
          position: fixed;
          right: var(--tl-space-4);
          bottom: var(--tl-space-4);
          z-index: var(--tl-z-toast);
          display: flex;
          flex-direction: column;
          gap: var(--tl-space-1);
          max-width: min(360px, calc(100vw - var(--tl-space-8)));
          padding: var(--tl-space-4);
          background: var(--tl-color-surface-raised);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-md);
          transform-origin: bottom right;
          transition-property: opacity, transform;
          transition-duration: var(--tl-motion-base);
          transition-timing-function: var(--tl-ease-standard);
        }

        /*
         * Reconnect / offline group (D-11 corrected by real-engine verification).
         * Phoenix LiveView applies connection lifecycle classes to the
         * `[data-phx-main]` container in this app. `.threadline-ui` is the scoped
         * Threadline shell inside that container, so selectors anchor on
         * `[data-phx-main].phx-*` and then descend into the shell. Never anchor on
         * the document body or the legacy disconnected class. Zero new JS/deps,
         * CSP-clean — it catches a dropped socket mid-session, unlike a mount-time
         * connected?/1 assign.
         *
         * The reconnect banner is hidden by default and revealed only while the
         * socket is loading/erroring. Mutating controls marked `data-tl-mutating`
         * are disabled (affordance: pointer-events + dimming); the markup also
         * carries aria-disabled + tabindex=-1 for links so the affordance is also
         * announced/keyboard-safe (Pitfall 6 — affordance is not enforcement).
         */
        .tl-reconnect-banner {
          display: none;
        }

        [data-phx-main].phx-loading .threadline-ui .tl-reconnect-banner,
        [data-phx-main].phx-error .threadline-ui .tl-reconnect-banner,
        [data-phx-main].phx-client-error .threadline-ui .tl-reconnect-banner {
          display: flex;
          align-items: center;
          gap: var(--tl-gap-inline);
          padding: var(--tl-space-2) var(--tl-space-4);
          color: var(--tl-color-warning-text);
          background: var(--tl-color-warning-bg);
          border-bottom: 1px solid var(--tl-color-warning-border);
        }

        [data-phx-main].phx-loading .threadline-ui [data-tl-mutating],
        [data-phx-main].phx-error .threadline-ui [data-tl-mutating],
        [data-phx-main].phx-client-error .threadline-ui [data-tl-mutating] {
          pointer-events: none;
          opacity: 0.55;
        }

        /*
         * Motion — purposeful, brand-coherent micro-interactions.
         * Pure CSS, GPU-only (transform/opacity), reusing the motion tokens.
         * Each fires on element mount; LiveView streams replay them only for
         * newly inserted/changed rows, so a freshly prune-run row or a
         * just-opened drawer animates while unchanged rows stay put. All
         * auto-degrade via the prefers-reduced-motion blanket below. The
         * high-traffic timeline stream is deliberately NOT animated — snappy
         * paging beats an entrance flourish (never animate high-frequency
         * actions).
         */

        /* C1 — a new retention run (the prune-now confirmation) rises in. */
        #retention-runs > tr {
          animation: tl-rise-in var(--tl-motion-base) var(--tl-ease-out) both;
        }

        /* C4 — opening row history: the drawer's history items stagger in,
         * reading as the timeline thread continuing into the drawer. */
        .tl-subview__timeline > * {
          animation: tl-rise-in var(--tl-motion-base) var(--tl-ease-out) both;
        }

        .tl-subview__timeline > *:nth-child(2) {
          animation-delay: var(--tl-motion-stagger);
        }

        .tl-subview__timeline > *:nth-child(3) {
          animation-delay: calc(var(--tl-motion-stagger) * 2);
        }

        .tl-subview__timeline > *:nth-child(4) {
          animation-delay: calc(var(--tl-motion-stagger) * 3);
        }

        .tl-subview__timeline > *:nth-child(n + 5) {
          animation-delay: calc(var(--tl-motion-stagger) * 4);
        }

        /* Evidence proofs and actor transactions are low-frequency reveals:
         * a gentle fade as the records assemble. (Actor rows are scoped to
         * #transactions-list so the shared .tl-change on the timeline is
         * untouched.) */
        .tl-record-list > .tl-record-card,
        #transactions-list > .tl-change {
          animation: tl-fade-in var(--tl-motion-base) var(--tl-ease-out) both;
        }

        /* C2 — copy id affordance. Vanilla embedded JS (operator_surface/script.ex)
         * toggles .is-copied on success: a Signal-Cyan pulse + a "Copied" chip.
         * The chip is a static ::after (not animated) so it still confirms under
         * prefers-reduced-motion; only the pulse is motion. */
        .tl-copy {
          position: relative;
          display: inline-flex;
          align-items: center;
          min-height: var(--tl-control-height-chip);
          padding: 0 var(--tl-space-2);
          border: 1px solid var(--tl-color-border);
          border-radius: var(--tl-radius-sm);
          background: transparent;
          color: var(--tl-color-muted);
          font-family: inherit;
          font-size: var(--tl-font-size-xs);
          cursor: pointer;
          transition: var(--tl-transition-fast);
        }

        .tl-copy:hover {
          color: var(--tl-color-text);
          border-color: var(--tl-color-border-strong);
        }

        .tl-copy.is-copied {
          color: var(--tl-color-signal);
          border-color: var(--tl-color-signal-border);
          animation: tl-copy-pulse var(--tl-motion-base) var(--tl-ease-out);
        }

        .tl-copy.is-copied::after {
          content: "Copied";
          position: absolute;
          bottom: calc(100% + var(--tl-space-1));
          left: 50%;
          transform: translateX(-50%);
          padding: 2px var(--tl-space-2);
          border-radius: var(--tl-radius-sm);
          background: var(--tl-color-signal-bg);
          color: var(--tl-color-signal);
          border: 1px solid var(--tl-color-signal-border);
          font-size: var(--tl-font-size-xs);
          white-space: nowrap;
          pointer-events: none;
        }

        @keyframes tl-copy-pulse {
          from {
            box-shadow: 0 0 0 0 var(--tl-color-signal-border);
          }
          to {
            box-shadow: 0 0 0 6px transparent;
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
          grid-template-columns: 1fr;
          gap: var(--tl-space-1);
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
          font-family: var(--tl-font-mono);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-page-band {
          display: grid;
          gap: var(--tl-space-3);
          margin-bottom: var(--tl-space-4);
        }

        .tl-journey-rail {
          position: relative;
          display: grid;
          grid-template-columns: 1fr;
          gap: var(--tl-space-2);
          margin-top: var(--tl-space-3);
        }

        /* Signature beat: a Signal-Cyan thread draws across the journey steps on
           enter — the one branded motion moment, tying the steps into a thread. */
        .tl-journey-rail::before {
          content: "";
          position: absolute;
          top: calc(-1 * var(--tl-space-1));
          left: 0;
          right: 0;
          height: 2px;
          border-radius: var(--tl-radius-pill);
          background: linear-gradient(90deg, var(--tl-color-signal), var(--tl-color-signal-border) 70%, transparent);
          transform: scaleX(0);
          transform-origin: left center;
          animation: tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both;
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

        #tl-main > .tl-trust-rail {
          margin-bottom: var(--tl-space-4);
        }

        .tl-trust-rail__label {
          color: var(--tl-color-muted);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
          font-weight: var(--tl-weight-strong);
        }

        .tl-table--coverage .tl-table__actions {
          white-space: normal;
        }

        .tl-table--coverage td[data-label="TABLE"] code {
          display: inline-block;
          max-width: 100%;
          min-width: 0;
        }

        .tl-record-list {
          display: grid;
          gap: var(--tl-space-3);
        }

        .tl-record-card {
          display: grid;
          grid-template-columns: 1fr;
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
          justify-content: flex-start;
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

        /* Mobile-first base: responsive tables stack into labelled cards.
           The desktop dense/operator layer starts at 1280px and restores the real table. */
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

        .tl-policy__summary {
          position: relative;
          padding-left: calc(var(--tl-space-4) + var(--tl-space-3) + var(--tl-chevron-size));
        }

        .tl-policy__summary::before {
          content: "";
          position: absolute;
          left: var(--tl-space-4);
          top: calc(var(--tl-space-4) + var(--tl-chevron-size) / 2);
          width: var(--tl-chevron-size);
          height: var(--tl-chevron-size);
          border-right: var(--tl-chevron-stroke) solid var(--tl-color-muted);
          border-bottom: var(--tl-chevron-stroke) solid var(--tl-color-muted);
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

        /* C5 — when redaction drift clears to zero, a Signal-Cyan thread draws
         * across the "all clear" message: the consequential "trust restored"
         * beat. One-shot, left-to-right, like the hero/journey signature. */
        .tl-policy__success {
          position: relative;
          overflow: hidden;
          margin: 0 0 var(--tl-space-4);
          padding: var(--tl-space-3) var(--tl-space-4);
          border: 1px solid var(--tl-color-success-border);
          border-radius: var(--tl-radius-lg);
          background: var(--tl-color-success-bg);
          color: var(--tl-color-success-text);
          font-size: var(--tl-font-size-label);
          line-height: var(--tl-line-label);
        }

        .tl-policy__success::after {
          content: "";
          position: absolute;
          inset: auto 0 0 0;
          height: 2px;
          background: var(--tl-color-signal);
          transform: scaleX(0);
          transform-origin: left center;
          animation: tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both;
        }

        .tl-job__actions {
          min-width: min(220px, 100%);
        }

        .tl-job__source {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          justify-content: flex-start;
          gap: var(--tl-space-2);
          padding-top: var(--tl-space-2);
          border-top: 1px solid var(--tl-color-border);
        }

        /* Tablet enhancement layer starts at 768px: lift the phone refinements once there's room. */
        @media (min-width: 768px) {
          .threadline-ui {
            display: grid;
            grid-template-columns: minmax(196px, 232px) minmax(0, 1fr);
            grid-template-rows: auto 1fr;
            column-gap: var(--tl-shell-gutter);
            /* Desktop has no collapsed nav summary above content — topbar only. */
            scroll-padding-top: calc(var(--tl-header-height) + var(--tl-space-4));
          }

          .tl-topbar {
            grid-column: 1 / -1;
          }

          .tl-shell-nav {
            grid-column: 1;
            grid-row: 2;
            top: var(--tl-header-height-mobile);
            align-self: start;
            height: calc(100vh - var(--tl-header-height-mobile));
            overflow: auto;
            border-right: 1px solid var(--tl-color-border);
            border-bottom: 0;
          }

          .tl-shell-nav__toggle {
            display: none;
          }

          .tl-shell-nav__panel,
          .tl-shell-nav[open] .tl-shell-nav__panel {
            display: grid;
            padding: var(--tl-space-4) var(--tl-space-3);
            border-top: 0;
          }

          .tl-page {
            grid-column: 2;
            grid-row: 2;
            min-width: 0;
            padding: var(--tl-space-3);
          }

          /* Reconcile the anchored-target offset to the DESKTOP sticky-topbar
             height so a deep-linked row clears the topbar instead of hiding
             beneath it. Matches the desktop scroll-padding-top above; the base
             rule keeps the mobile offset for phone-width sticky headers. */
          .tl-target-row {
            scroll-margin-top: calc(var(--tl-header-height) + var(--tl-space-4));
          }

          .threadline-ui > :not(.tl-skip-link):not(.tl-topbar):not(.tl-shell-nav) {
            grid-column: 2;
            min-width: 0;
          }

          .tl-home__headline {
            font-size: var(--tl-font-size-display);
          }

          .threadline-ui .tl-shell-nav__item {
            min-height: var(--tl-control-height-compact);
          }

          .tl-timeline-command__facts {
            grid-template-columns: repeat(3, minmax(0, 1fr));
          }

          .tl-filter-grid--primary {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }

          .tl-filter-grid--advanced {
            grid-template-columns: repeat(3, minmax(0, 1fr));
          }
        }

        /* Desktop dense/operator layer starts at 1280px: full multi-column layout and sticky chrome. */
        @media (min-width: 1280px) {
          .tl-page {
            padding: var(--tl-space-4);
          }

          .tl-home__hero {
            padding: var(--tl-space-10) 0 var(--tl-space-6);
          }

          .tl-home__cards {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }

          .tl-home__earned-flow {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }

          .tl-home__card {
            padding: var(--tl-space-6);
          }

          .tl-stress__metrics {
            grid-template-columns: repeat(4, minmax(0, 1fr));
          }

          .tl-stress__layout {
            grid-template-columns: minmax(280px, 360px) minmax(0, 1fr);
          }

          .tl-orientation {
            padding: var(--tl-space-4);
          }

          .tl-orientation__actions {
            justify-content: flex-end;
          }

          .tl-toolbar {
            position: sticky;
            padding: var(--tl-space-4);
          }

          .tl-toolbar.tl-timeline-command {
            position: static;
            padding: var(--tl-space-3);
          }

          .tl-timeline-command__summary {
            grid-template-columns: minmax(240px, .85fr) minmax(0, 1.15fr);
            align-items: center;
          }

          .tl-filter-grid--primary {
            grid-template-columns: minmax(178px, .8fr) minmax(178px, .8fr) minmax(180px, 1fr) minmax(240px, 1.3fr);
          }

          .tl-toolbar__actions {
            grid-column: 1 / -1;
            justify-content: flex-end;
          }

          .tl-timeline-command__utilities {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }

          .tl-utility-group__label {
            flex-basis: auto;
            min-width: 52px;
          }

          .tl-page__header {
            display: flex;
          }

          .tl-subview__content {
            grid-template-columns: minmax(180px, 240px) minmax(0, 1fr);
          }

          .tl-change__summary {
            grid-template-columns: minmax(160px, 1fr) minmax(220px, 1.5fr) auto;
          }

          .tl-job__main {
            grid-template-columns: minmax(0, 1fr) auto;
          }

          .tl-job__meta,
          .tl-summary-grid,
          .tl-journey-rail {
            grid-template-columns: repeat(3, minmax(0, 1fr));
          }

          .tl-job__summary,
          .tl-job__actions {
            align-items: center;
          }

          .tl-job__summary {
            flex-direction: row;
          }

          .tl-change__actions {
            justify-content: flex-end;
          }

          .tl-topbar {
            min-height: var(--tl-header-height);
            flex-wrap: nowrap;
            gap: var(--tl-space-3);
            padding: var(--tl-space-1) var(--tl-space-4);
          }

          .tl-topbar__brand-logo {
            width: var(--tl-brand-logo-width-desktop);
            height: var(--tl-brand-logo-height-desktop);
            flex-basis: var(--tl-brand-logo-width-desktop);
          }

          .tl-shell-nav {
            top: var(--tl-header-height);
            height: calc(100vh - var(--tl-header-height));
          }

          .tl-topbar__status {
            flex-basis: auto;
          }

          .tl-topbar__status .tl-chip {
            max-width: min(32ch, 32vw);
          }

          .tl-action-group--secondary {
            padding-left: var(--tl-space-2);
            border-left: 1px solid var(--tl-color-border);
          }

          .tl-subview-backdrop {
            inset: var(--tl-header-height) 0 0;
          }

          .tl-subview {
            top: var(--tl-header-height);
            width: min(var(--tl-drawer-width), 100vw);
            min-height: auto;
          }

          .tl-kv__row {
            grid-template-columns: minmax(120px, 180px) minmax(0, 1fr);
            gap: var(--tl-space-3);
          }

          .tl-record-card {
            grid-template-columns: minmax(0, 1fr) auto;
          }

          .tl-record-card__actions {
            justify-content: flex-end;
          }

          .tl-job__source {
            justify-content: space-between;
          }

          .tl-table-wrap .tl-table--responsive {
            min-width: var(--tl-table-min-width);
          }

          .tl-table--responsive thead {
            display: table-header-group;
          }

          .tl-table--responsive {
            display: table;
            width: 100%;
          }

          .tl-table--coverage {
            table-layout: fixed;
          }

          .tl-table--coverage th:nth-child(1),
          .tl-table--coverage td:nth-child(1) {
            width: 22%;
          }

          .tl-table--coverage th:nth-child(2),
          .tl-table--coverage td:nth-child(2) {
            width: 16%;
          }

          .tl-table--coverage th:nth-child(3),
          .tl-table--coverage td:nth-child(3) {
            width: 14%;
          }

          .tl-table--coverage th:nth-child(4),
          .tl-table--coverage td:nth-child(4) {
            width: 48%;
          }

          .tl-table--responsive tbody {
            display: table-row-group;
            width: auto;
          }

          .tl-table--responsive tr {
            display: table-row;
            width: auto;
            padding: 0;
            border-bottom: 0;
          }

          .tl-table--responsive td {
            display: table-cell;
            width: auto;
            grid-template-columns: none;
            gap: 0;
            padding: var(--tl-space-2) var(--tl-space-4);
            border-bottom: 1px solid var(--tl-color-border);
          }

          .tl-table--compact.tl-table--responsive td {
            padding-top: var(--tl-row-padding-compact);
            padding-bottom: var(--tl-row-padding-compact);
          }

          .tl-table--responsive td::before {
            content: none;
            display: none;
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .threadline-ui *,
          .threadline-ui *::before,
          .threadline-ui *::after,
          .tl-policy__row::details-content {
            transition-duration: 1ms !important;
            animation-duration: 1ms !important;
            animation-delay: 0ms !important;
            animation-iteration-count: 1 !important;
            scroll-behavior: auto !important;
          }

          .tl-fade-in,
          .tl-fade-out,
          .tl-rise-in,
          .tl-rise-out,
          .tl-slide-in-right,
          .tl-slide-out-right,
          .tl-modal,
          .tl-drawer,
          .tl-popover,
          .tl-shadow-popover,
          .tl-accordion__panel,
          .tl-toast,
          .tl-policy__row::details-content {
            transition-duration: 1ms !important;
            animation-duration: 1ms !important;
            animation-delay: 0ms !important;
          }

          .translate-y-4,
          .translate-x-full,
          .tl-popover,
          .tl-shadow-popover,
          .tl-accordion__panel,
          .tl-button:active:not(:disabled):not([disabled]):not([aria-disabled="true"]) {
            transform: none;
          }

          .tl-subview {
            animation: none !important;
            transform: none !important;
          }
        }
      </style>
      """
    end

    defp font_face_style do
      case Threadline.OperatorSurface.Fonts.face_css() do
        "" -> ""
        css -> "<style>" <> css <> "</style>"
      end
    end
  end
end
