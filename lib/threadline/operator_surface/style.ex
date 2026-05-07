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
          --tl-spacing-xs: 4px;
          --tl-spacing-sm: 8px;
          --tl-spacing-md: 16px;

          --tl-font-body: 14px;
          --tl-font-label: 12px;

          --tl-color-main: #FFFFFF;
          --tl-color-secondary: #F3F4F6;
          --tl-color-accent: #3B82F6;
          --tl-color-destructive: #EF4444;
          --tl-color-text: #111827;
          --tl-color-text-muted: #6B7280;

          --tl-header-height: 36px;

          font-family: system-ui, -apple-system, sans-serif;
          font-size: var(--tl-font-body);
          color: var(--tl-color-text);
          background-color: var(--tl-color-main);
          line-height: 1.5;
        }

        .threadline-ui .empty-state {
          padding: var(--tl-spacing-md);
          color: var(--tl-color-text-muted);
          text-align: center;
          background-color: var(--tl-color-secondary);
          border-radius: 6px;
          margin: var(--tl-spacing-md) 0;
        }

        .threadline-ui .transaction-header {
          padding: var(--tl-spacing-md);
          border-bottom: 1px solid var(--tl-color-secondary);
          margin-bottom: var(--tl-spacing-md);
        }

        .threadline-ui .transaction-header h2 {
          margin: 0;
          font-size: 18px;
          font-weight: 600;
        }

        .threadline-ui .viewport-container {
          max-height: 600px;
          overflow-y: auto;
          border: 1px solid var(--tl-color-secondary);
          border-radius: 6px;
        }

        .threadline-ui .change-row {
          padding: var(--tl-spacing-md);
          border-bottom: 1px solid var(--tl-color-secondary);
        }

        .threadline-ui .change-row:last-child {
          border-bottom: none;
        }

        .threadline-ui .change-header {
          display: flex;
          gap: var(--tl-spacing-sm);
          font-size: var(--tl-font-label);
          color: var(--tl-color-text-muted);
          margin-bottom: var(--tl-spacing-sm);
        }

        .threadline-ui .change-op {
          font-weight: 600;
          color: var(--tl-color-accent);
          text-transform: uppercase;
        }

        .threadline-ui .change-table {
          font-family: monospace;
          background-color: var(--tl-color-secondary);
          padding: 2px var(--tl-spacing-xs);
          border-radius: 4px;
        }

        .threadline-ui .change-fields {
          display: flex;
          flex-direction: column;
          gap: var(--tl-spacing-xs);
        }

        .threadline-ui .field-diff {
          font-family: monospace;
          font-size: var(--tl-font-label);
          background-color: var(--tl-color-secondary);
          padding: var(--tl-spacing-xs) var(--tl-spacing-sm);
          border-radius: 4px;
        }

        .threadline-ui .field-name {
          font-weight: 600;
          color: var(--tl-color-text);
        }

        .threadline-ui .field-before {
          color: var(--tl-color-destructive);
          text-decoration: line-through;
        }

        .threadline-ui .field-prior-omitted {
          color: var(--tl-color-text-muted);
          font-style: italic;
        }

        .threadline-ui .field-after {
          color: var(--tl-color-accent);
        }

        .threadline-ui .timeline-toolbar {
          position: sticky;
          top: var(--tl-header-height, 36px);
          background: var(--tl-color-main);
          border-bottom: 1px solid var(--tl-color-secondary);
          padding: var(--tl-spacing-md);
          z-index: 1;
        }

        .threadline-ui .timeline-toolbar form {
          display: flex;
          flex-wrap: wrap;
          gap: var(--tl-spacing-md);
          align-items: end;
        }

        .threadline-ui .timeline-toolbar label {
          display: flex;
          flex-direction: column;
          font-size: var(--tl-font-label);
          color: var(--tl-color-text-muted);
          gap: var(--tl-spacing-xs);
        }

        .threadline-ui .timeline-toolbar input,
        .threadline-ui .timeline-toolbar select {
          padding: var(--tl-spacing-xs) var(--tl-spacing-sm);
          border: 1px solid var(--tl-color-secondary);
          border-radius: 4px;
          font: inherit;
        }

        .threadline-ui .timeline-toolbar small {
          color: var(--tl-color-text-muted);
          font-size: 11px;
        }

        .threadline-ui .button-cluster {
          margin-left: auto;
          display: flex;
          gap: var(--tl-spacing-sm);
          align-items: center;
        }

        .threadline-ui .button-cluster button {
          padding: var(--tl-spacing-xs) var(--tl-spacing-md);
          background: var(--tl-color-accent);
          color: var(--tl-color-main);
          border: 0;
          border-radius: 4px;
          cursor: pointer;
        }

        .threadline-ui .button-cluster .download-button {
          padding: var(--tl-spacing-xs) var(--tl-spacing-md);
          background: var(--tl-color-secondary);
          color: var(--tl-color-text);
          border: 1px solid var(--tl-color-secondary);
          border-radius: 4px;
          text-decoration: none;
          cursor: pointer;
        }

        .threadline-ui .clear-link {
          color: var(--tl-color-text-muted);
          text-decoration: underline;
          font-size: var(--tl-font-label);
        }

        .threadline-ui .filter-error {
          padding: var(--tl-spacing-md);
          margin: var(--tl-spacing-md);
          background: var(--tl-color-secondary);
          color: var(--tl-color-destructive);
          border-radius: 4px;
        }

        .threadline-ui .filter-hint {
          font-size: var(--tl-font-label);
          color: var(--tl-color-text-muted);
        }

        .threadline-ui .match-count-status {
          padding: var(--tl-spacing-sm) var(--tl-spacing-md);
          font-size: var(--tl-font-label);
          color: var(--tl-color-text-muted);
          border-bottom: 1px solid var(--tl-color-secondary);
        }

        .threadline-ui .policy-redaction-page {
          padding: var(--tl-spacing-md);
        }

        .threadline-ui .policy-redaction-summary {
          margin-bottom: var(--tl-spacing-md);
        }

        .threadline-ui .policy-redaction-summary h2 {
          margin: 0 0 var(--tl-spacing-xs);
          font-size: 18px;
          font-weight: 600;
        }

        .threadline-ui .policy-redaction-section {
          margin-bottom: var(--tl-spacing-md);
          border: 1px solid var(--tl-color-secondary);
          border-radius: 6px;
          overflow: hidden;
        }

        .threadline-ui .policy-redaction-section-header {
          padding: var(--tl-spacing-sm) var(--tl-spacing-md);
          background: var(--tl-color-secondary);
          border-bottom: 1px solid var(--tl-color-secondary);
        }

        .threadline-ui .policy-redaction-section-header h3 {
          margin: 0;
          font-size: 15px;
        }

        .threadline-ui .policy-redaction-section--drift .policy-redaction-section-header {
          border-left: 3px solid #F59E0B;
        }

        .threadline-ui .policy-redaction-section--introspect .policy-redaction-section-header {
          border-left: 3px solid var(--tl-color-destructive);
        }

        .threadline-ui .policy-redaction-section--match .policy-redaction-section-header {
          border-left: 3px solid #9CA3AF;
        }

        .threadline-ui .policy-redaction-empty {
          margin: 0;
          padding: var(--tl-spacing-md);
          color: var(--tl-color-text-muted);
        }

        .threadline-ui .policy-redaction-row {
          border-bottom: 1px solid var(--tl-color-secondary);
        }

        .threadline-ui .policy-redaction-row:last-child {
          border-bottom: 0;
        }

        .threadline-ui .policy-redaction-row summary {
          list-style: none;
          cursor: pointer;
          padding: var(--tl-spacing-md);
        }

        .threadline-ui .policy-redaction-row summary::-webkit-details-marker {
          display: none;
        }

        .threadline-ui .policy-redaction-row-main {
          display: flex;
          gap: var(--tl-spacing-sm);
          align-items: baseline;
          margin-bottom: var(--tl-spacing-xs);
        }

        .threadline-ui .policy-redaction-table {
          font-family: monospace;
          font-weight: 600;
        }

        .threadline-ui .policy-redaction-status {
          font-size: var(--tl-font-label);
          color: var(--tl-color-text-muted);
        }

        .threadline-ui .policy-redaction-row--match .policy-redaction-status,
        .threadline-ui .policy-redaction-row--match .policy-redaction-hint {
          color: var(--tl-color-text-muted);
        }

        .threadline-ui .policy-redaction-hint,
        .threadline-ui .policy-redaction-warning {
          margin: 0;
          font-size: var(--tl-font-label);
        }

        .threadline-ui .policy-redaction-warning {
          margin-top: var(--tl-spacing-xs);
          color: var(--tl-color-destructive);
        }

        .threadline-ui .policy-redaction-details {
          padding: 0 var(--tl-spacing-md) var(--tl-spacing-md);
        }

        .threadline-ui .policy-redaction-detail-table {
          width: 100%;
          border-collapse: collapse;
          font-size: var(--tl-font-label);
        }

        .threadline-ui .policy-redaction-detail-table th,
        .threadline-ui .policy-redaction-detail-table td {
          padding: var(--tl-spacing-xs) var(--tl-spacing-sm);
          border-top: 1px solid var(--tl-color-secondary);
          text-align: left;
          vertical-align: top;
        }

        .threadline-ui .policy-redaction-detail-table tbody th {
          width: 140px;
          font-weight: 600;
        }

        .threadline-ui .truncation-banner {
          padding: var(--tl-spacing-sm) var(--tl-spacing-md);
          margin: var(--tl-spacing-sm) var(--tl-spacing-md);
          border-radius: 4px;
          font-size: var(--tl-font-label);
        }

        .threadline-ui .truncation-banner.informational {
          background: var(--tl-color-secondary);
          color: var(--tl-color-text-muted);
        }

        .threadline-ui .truncation-banner.warning {
          /* Amber band — distinct from .filter-error's destructive red.
             The warning band is data-loss-adjacent ("you're missing rows past 10,000")
             while the informational band is transport ("we're chunking, larger size").
             The two MUST be visually distinguishable per D-18. */
          background: #FEF3C7;            /* amber-50 */
          color: #92400E;                 /* amber-800 */
          border-left: 3px solid #F59E0B; /* amber-500 */
        }

        .threadline-ui .tx-link {
          color: var(--tl-color-accent);
          text-decoration: none;
        }

        .threadline-ui .timeline-rows {
          /* container that always renders so phx-update="stream" + phx-viewport-bottom
             bindings are present even on empty-data paths (BLOCKER 2 fix in Plan 01). */
          display: block;
        }

        .threadline-ui .change-time {
          color: var(--tl-color-text-muted);
          font-size: var(--tl-font-label);
        }

        .threadline-ui-header {
          position: sticky;
          top: 0;
          z-index: 2;
          height: var(--tl-header-height, 36px);
          background: var(--tl-color-main);
          border-bottom: 1px solid var(--tl-color-secondary);
          display: flex;
          align-items: center;
          gap: var(--tl-spacing-md);
          padding: 0 var(--tl-spacing-md);
          font-size: var(--tl-font-label, 12px);
        }

        .threadline-ui-header .brand {
          font-weight: 600;
        }

        .threadline-ui-header .stale-indicator {
          color: var(--tl-color-text-muted);
          font-size: 11px;
        }

        .threadline-ui .surface-badge {
          margin-left: auto;
          font-size: var(--tl-font-label, 12px);
          border-radius: 12px;
          padding: 4px 8px;
          text-decoration: none;
        }

        .threadline-ui .surface-badge--ok {
          color: var(--tl-color-text-muted);
          background: transparent;
          border: 1px solid var(--tl-color-secondary);
        }

        .threadline-ui .surface-badge--warn {
          background: #FEF3C7;
          color: #92400E;
          border-left: 3px solid #F59E0B;
        }

        .threadline-ui .coverage-page {
          padding: var(--tl-spacing-md);
        }

        .threadline-ui .coverage-table {
          width: 100%;
          border-collapse: collapse;
          margin-top: var(--tl-spacing-md);
        }

        .threadline-ui .coverage-table th {
          text-align: left;
          font-size: var(--tl-font-label, 12px);
          font-weight: 600;
          color: var(--tl-color-text-muted);
          border-bottom: 1px solid var(--tl-color-secondary);
          padding: var(--tl-spacing-sm) var(--tl-spacing-md);
        }

        .threadline-ui .coverage-table td {
          padding: var(--tl-spacing-sm) var(--tl-spacing-md);
          font-family: ui-monospace, monospace;
          font-size: var(--tl-font-label, 12px);
        }

        .threadline-ui .coverage-row--covered {
          background: transparent;
        }

        .threadline-ui .coverage-row--uncovered {
          background: rgba(239, 68, 68, 0.06);
        }

        .threadline-ui .coverage-row--expected {
          background: var(--tl-color-secondary);
          color: var(--tl-color-text-muted);
        }
      </style>
      """
    end
  end
end
