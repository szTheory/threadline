defmodule Threadline.Evidence.Subject do
  @moduledoc """
  The closed set of subject names accepted by Threadline evidence records.

  Use `supported_subjects/0` to inspect the names, `validate/1` to check a
  subject or descriptor, and `supported?/1` when a boolean result is enough.
  """

  @supported_subjects [
    "redaction_policy",
    "trigger_coverage",
    "retention_run",
    "retention_policy",
    "export_delivery",
    "support_scope_posture"
  ]

  @typedoc "A subject name or a map descriptor using the `:subject` or `:name` key."
  @type subject_descriptor ::
          atom()
          | String.t()
          | %{optional(:subject) => atom() | String.t(), optional(:name) => atom() | String.t()}
          | %{
              optional(String.t()) => atom() | String.t()
            }

  @doc """
  Returns the six subject names accepted by Evidence record writers.
  """
  @spec supported_subjects() :: [String.t()]
  def supported_subjects, do: @supported_subjects

  @doc """
  Validates a subject or subject descriptor against the closed inventory.
  """
  @spec validate(subject_descriptor()) :: :ok | {:error, {:unsupported_subject, term()}}
  def validate(subject) do
    case normalize(subject) do
      value when value in @supported_subjects -> :ok
      value -> {:error, {:unsupported_subject, value}}
    end
  end

  @doc """
  Returns whether a subject or subject descriptor is supported.
  """
  @spec supported?(subject_descriptor()) :: boolean()
  def supported?(subject), do: validate(subject) == :ok

  defp normalize(%{subject: subject}), do: normalize(subject)
  defp normalize(%{name: subject}), do: normalize(subject)
  defp normalize(%{"subject" => subject}), do: normalize(subject)
  defp normalize(%{"name" => subject}), do: normalize(subject)
  defp normalize(subject) when is_atom(subject), do: Atom.to_string(subject)
  defp normalize(subject) when is_binary(subject), do: subject
  defp normalize(subject), do: subject
end
