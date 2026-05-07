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
          top: 0;
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
      </style>
      """
    end
  end
end
