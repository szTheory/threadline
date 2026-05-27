defmodule Threadline.Evidence.Subject do
  @moduledoc """
  Closed subject inventory for Threadline-owned evidence records.

  Phase 95 keeps this boundary intentionally narrow so later evidence APIs and
  surfaces cannot silently expand into host-owned auth, tenancy, or compliance
  workflow semantics.
  """

  @supported_subjects [
    "redaction_policy",
    "trigger_coverage",
    "retention_run",
    "retention_policy",
    "export_delivery",
    "support_scope_posture"
  ]

  @type subject_descriptor ::
          atom()
          | String.t()
          | %{optional(:subject) => atom() | String.t(), optional(:name) => atom() | String.t()}
          | %{
              optional(String.t()) => atom() | String.t()
            }

  @doc """
  Returns the closed supported subject inventory for v1.22.
  """
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
