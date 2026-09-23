defmodule Threadline.CommunityHealthRenderContractTest do
  @moduledoc """
  Deterministic stand-in for the one community-health check a human cannot run.

  GitHub redirects signed-out issue creation to login, and the only
  authenticated identity available here is the repository owner, whose chooser
  can include maintainer-only controls. So "does the intake render for an
  outsider?" is not directly observable by anyone.

  What *is* observable is the contract that decides the answer: GitHub renders
  an issue form when, and only when, its YAML conforms to the issue-forms
  schema. A form that misses a required attribute, names an unknown `type`, or
  reuses an `id` does not render — GitHub silently falls back to a blank issue
  body, and the intake guarantees in `SECURITY.md` and the chooser quietly stop
  applying. This suite parses the real YAML and checks that schema, so the
  failure mode that would break the outsider render fails a test instead.

  Every rule is paired with a negative fixture below, so the suite cannot pass
  by checking nothing.
  """
  use ExUnit.Case, async: true

  @issue_template_dir ".github/ISSUE_TEMPLATE"
  @chooser Path.join(@issue_template_dir, "config.yml")

  @body_types ~w(checkboxes dropdown input markdown textarea)
  @id_format ~r/^[a-zA-Z0-9_-]+$/

  describe "published issue forms" do
    test "every form in .github/ISSUE_TEMPLATE conforms to GitHub's issue-forms schema" do
      forms = issue_form_paths()

      assert forms != [], "no issue forms found in #{@issue_template_dir}"

      for path <- forms do
        assert form_errors(YamlElixir.read_from_file!(path)) == [],
               "#{path} would not render: #{inspect(form_errors(YamlElixir.read_from_file!(path)))}"
      end
    end

    test "form names are unique so the chooser cannot show two identical entries" do
      names =
        Enum.map(issue_form_paths(), fn path ->
          YamlElixir.read_from_file!(path)["name"]
        end)

      assert names == Enum.uniq(names), "duplicate issue-form names: #{inspect(names)}"
    end

    test "the chooser config conforms to the schema that decides what an outsider sees" do
      assert chooser_errors(YamlElixir.read_from_file!(@chooser)) == [],
             "#{@chooser}: #{inspect(chooser_errors(YamlElixir.read_from_file!(@chooser)))}"
    end

    test "every chooser contact link is an absolute https URL" do
      config = YamlElixir.read_from_file!(@chooser)

      for link <- config["contact_links"] || [] do
        assert String.starts_with?(link["url"], "https://"),
               "contact link #{inspect(link["name"])} is not an absolute https URL"
      end
    end
  end

  describe "validator non-vacuity" do
    # Each fixture below starts from a form that PASSES and breaks exactly one
    # rule, proving the rule is load-bearing rather than decorative.

    test "a valid minimal form passes" do
      assert form_errors(valid_form()) == []
    end

    test "a missing top-level key is rejected" do
      for key <- ~w(name description body) do
        assert {:missing_key, key} in form_errors(Map.delete(valid_form(), key)),
               "deleting #{key} did not fail the form"
      end
    end

    test "an empty body is rejected" do
      assert :empty_body in form_errors(Map.put(valid_form(), "body", []))
    end

    test "an unknown body type is rejected" do
      broken = put_in(valid_form(), ["body", Access.at(0), "type"], "textarea ")

      assert {:unknown_type, 0, "textarea "} in form_errors(broken)
    end

    test "a body element missing a required attribute is rejected" do
      broken = put_in(valid_form(), ["body", Access.at(0), "attributes"], %{})

      assert {:missing_attribute, 0, "label"} in form_errors(broken)
    end

    test "a markdown element without a value is rejected" do
      broken =
        Map.put(valid_form(), "body", [%{"type" => "markdown", "attributes" => %{}}])

      assert {:missing_attribute, 0, "value"} in form_errors(broken)
    end

    test "a dropdown with no options is rejected" do
      broken =
        Map.put(valid_form(), "body", [
          %{"type" => "dropdown", "attributes" => %{"label" => "Pick", "options" => []}}
        ])

      assert {:empty_options, 0} in form_errors(broken)
    end

    test "checkbox options without labels are rejected" do
      broken =
        Map.put(valid_form(), "body", [
          %{
            "type" => "checkboxes",
            "attributes" => %{"label" => "Confirm", "options" => [%{"required" => true}]}
          }
        ])

      assert {:unlabeled_option, 0, 0} in form_errors(broken)
    end

    test "duplicate element ids are rejected" do
      element = %{"type" => "input", "id" => "same", "attributes" => %{"label" => "A"}}

      broken =
        Map.put(valid_form(), "body", [element, %{element | "attributes" => %{"label" => "B"}}])

      assert {:duplicate_id, "same"} in form_errors(broken)
    end

    test "a malformed element id is rejected" do
      broken = put_in(valid_form(), ["body", Access.at(0), "id"], "not valid")

      assert {:malformed_id, "not valid"} in form_errors(broken)
    end

    test "validations on a markdown element are rejected" do
      broken =
        Map.put(valid_form(), "body", [
          %{
            "type" => "markdown",
            "attributes" => %{"value" => "hi"},
            "validations" => %{"required" => true}
          }
        ])

      assert {:validations_not_allowed, 0} in form_errors(broken)
    end

    test "a non-boolean validations.required is rejected" do
      broken =
        put_in(valid_form(), ["body", Access.at(0), "validations"], %{"required" => "yes"})

      assert {:non_boolean_required, 0} in form_errors(broken)
    end

    test "a valid chooser passes and each broken chooser rule is rejected" do
      valid = %{
        "blank_issues_enabled" => false,
        "contact_links" => [
          %{"name" => "Security", "url" => "https://example.com", "about" => "Report privately"}
        ]
      }

      assert chooser_errors(valid) == []

      assert :blank_issues_enabled_not_boolean in chooser_errors(%{
               valid
               | "blank_issues_enabled" => "false"
             })

      assert {:missing_contact_link_key, 0, "about"} in chooser_errors(
               put_in(valid, ["contact_links", Access.at(0)], %{
                 "name" => "Security",
                 "url" => "https://example.com"
               })
             )
    end
  end

  # -- validators -------------------------------------------------------------

  defp issue_form_paths do
    @issue_template_dir
    |> File.ls!()
    |> Enum.filter(&(&1 != "config.yml" and String.ends_with?(&1, [".yml", ".yaml"])))
    |> Enum.sort()
    |> Enum.map(&Path.join(@issue_template_dir, &1))
  end

  defp valid_form do
    %{
      "name" => "Bug report",
      "description" => "Something is broken",
      "body" => [%{"type" => "textarea", "attributes" => %{"label" => "Reproduction"}}]
    }
  end

  defp form_errors(form) when is_map(form) do
    missing =
      for key <- ~w(name description body),
          missing_top_level?(key, form[key]),
          do: {:missing_key, key}

    body = form["body"]

    cond do
      missing != [] -> missing
      body == [] -> [:empty_body]
      true -> body |> Enum.with_index() |> Enum.flat_map(&element_errors/1) |> dedupe_ids(body)
    end
  end

  defp form_errors(_), do: [{:missing_key, "name"}]

  # An absent or non-list `body` is a missing key; a present-but-empty one is
  # reported as :empty_body so the two failure shapes stay distinguishable.
  defp missing_top_level?("body", value), do: not is_list(value)
  defp missing_top_level?(_key, value), do: blank?(value)

  defp element_errors({element, index}) when is_map(element) do
    type = element["type"]

    type_errors =
      if type in @body_types, do: [], else: [{:unknown_type, index, type}]

    id_errors =
      case element["id"] do
        nil ->
          []

        id when is_binary(id) ->
          if Regex.match?(@id_format, id), do: [], else: [{:malformed_id, id}]

        id ->
          [{:malformed_id, id}]
      end

    type_errors ++
      id_errors ++
      attribute_errors(type, element, index) ++
      validation_errors(type, element, index)
  end

  defp element_errors({_element, index}), do: [{:unknown_type, index, nil}]

  defp attribute_errors("markdown", element, index),
    do: required_attributes(element, index, ["value"])

  defp attribute_errors(type, element, index) when type in ["input", "textarea"],
    do: required_attributes(element, index, ["label"])

  defp attribute_errors("dropdown", element, index) do
    required_attributes(element, index, ["label", "options"]) ++
      options_errors(element, index, :strings)
  end

  defp attribute_errors("checkboxes", element, index) do
    required_attributes(element, index, ["label", "options"]) ++
      options_errors(element, index, :objects)
  end

  defp attribute_errors(_type, _element, _index), do: []

  defp required_attributes(element, index, keys) do
    attributes = element["attributes"] || %{}

    for key <- keys, blank?(attributes[key]), do: {:missing_attribute, index, key}
  end

  defp options_errors(element, index, shape) do
    case get_in(element, ["attributes", "options"]) do
      options when is_list(options) and options != [] ->
        option_shape_errors(options, index, shape)

      options when is_list(options) ->
        [{:empty_options, index}]

      nil ->
        []

      _ ->
        [{:empty_options, index}]
    end
  end

  defp option_shape_errors(options, index, :strings) do
    for {option, position} <- Enum.with_index(options),
        not is_binary(option) or String.trim(option) == "",
        do: {:unlabeled_option, index, position}
  end

  defp option_shape_errors(options, index, :objects) do
    for {option, position} <- Enum.with_index(options),
        not is_map(option) or blank?(option["label"]),
        do: {:unlabeled_option, index, position}
  end

  defp validation_errors("markdown", element, index) do
    if Map.has_key?(element, "validations"), do: [{:validations_not_allowed, index}], else: []
  end

  defp validation_errors(_type, element, index) do
    case get_in(element, ["validations", "required"]) do
      nil -> []
      value when is_boolean(value) -> []
      _ -> [{:non_boolean_required, index}]
    end
  end

  defp dedupe_ids(errors, body) do
    ids =
      body
      |> Enum.filter(&is_map/1)
      |> Enum.map(& &1["id"])
      |> Enum.reject(&is_nil/1)

    errors ++ for id <- ids -- Enum.uniq(ids), do: {:duplicate_id, id}
  end

  defp chooser_errors(config) when is_map(config) do
    blank_errors =
      case config["blank_issues_enabled"] do
        value when is_boolean(value) -> []
        _ -> [:blank_issues_enabled_not_boolean]
      end

    link_errors =
      config
      |> Map.get("contact_links", [])
      |> List.wrap()
      |> Enum.with_index()
      |> Enum.flat_map(fn {link, index} ->
        for key <- ~w(name url about),
            not is_map(link) or blank?(link[key]),
            do: {:missing_contact_link_key, index, key}
      end)

    blank_errors ++ link_errors
  end

  defp chooser_errors(_), do: [:blank_issues_enabled_not_boolean]

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?([]), do: true
  defp blank?(%{} = map), do: map_size(map) == 0
  defp blank?(_), do: false
end
