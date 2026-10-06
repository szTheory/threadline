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

  @typedoc ~S"""
  A subject name or descriptor. Recognized keys, in precedence order, are atom `:subject`, atom
  `:name`, string `"subject"`, and string `"name"`. Each recognized value may be an atom or
  string, and a value that is itself a descriptor is normalized recursively.

  When a recognized key is present, other keys are ignored. If a map has no recognized key, it is
  returned unchanged as the unsupported value. The string-key map arm also represents extra keys
  and mixed atom/string maps.
  """
  @type subject_descriptor ::
          atom()
          | String.t()
          | %{optional(:subject) => atom() | String.t(), optional(:name) => atom() | String.t()}
          | %{optional(String.t()) => atom() | String.t()}

  @typedoc "Any value accepted by the subject validator and predicate."
  @type subject_input ::
          atom()
          | bitstring()
          | number()
          | %{optional(subject_input()) => subject_input()}
          | tuple()
          | list()
          | pid()
          | port()
          | reference()
          | function()

  @doc """
  Returns the six subject names accepted by Evidence record writers.
  """
  @spec supported_subjects() :: [String.t()]
  def supported_subjects, do: @supported_subjects

  @doc """
  Returns `:ok` for a supported subject or `{:error, {:unsupported_subject, value}}` otherwise.

  The unsupported value is the normalized subject for recognized descriptors and the original
  input for values that cannot be normalized. The inventory is closed to `supported_subjects/0`.
  """
  @spec validate(subject_input()) :: :ok | {:error, {:unsupported_subject, term()}}
  def validate(subject) do
    case normalize(subject) do
      value when value in @supported_subjects -> :ok
      value -> {:error, {:unsupported_subject, value}}
    end
  end

  @doc """
  Returns `true` when a subject or subject descriptor is supported, and `false` for every other
  input.
  """
  @spec supported?(subject_input()) :: boolean()
  def supported?(subject), do: validate(subject) == :ok

  defp normalize(%{subject: subject}), do: normalize(subject)
  defp normalize(%{name: subject}), do: normalize(subject)
  defp normalize(%{"subject" => subject}), do: normalize(subject)
  defp normalize(%{"name" => subject}), do: normalize(subject)
  defp normalize(subject) when is_atom(subject), do: Atom.to_string(subject)
  defp normalize(subject) when is_binary(subject), do: subject
  defp normalize(subject), do: subject
end
