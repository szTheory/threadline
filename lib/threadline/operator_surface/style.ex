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
      </style>
      """
    end
  end
end
