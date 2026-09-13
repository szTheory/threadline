if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RenderedOutputContractTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Rendered output contract</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end
  end

  defmodule Threadline.OperatorSurface.RenderedOutputContractTest.Auth do
    def authorize(_), do: true
    def coverage_authorize(_), do: true
  end

  defmodule Threadline.OperatorSurface.RenderedOutputContractTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Threadline.OperatorSurface.RenderedOutputContractTest.FakeTicketReply do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "ticket_replies" do
      field(:body, :string)
    end
  end

  defmodule Threadline.OperatorSurface.RenderedOutputContractTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.RenderedOutputContractTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        repo: Threadline.Test.Repo,
        schemas: %{
          "ticket_replies" =>
            Threadline.OperatorSurface.RenderedOutputContractTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.RenderedOutputContractTest.FakeUser
        },
        coverage_authorize_fn:
          &Threadline.OperatorSurface.RenderedOutputContractTest.Auth.coverage_authorize/1,
        policy_authorize_fn:
          &Threadline.OperatorSurface.RenderedOutputContractTest.Auth.authorize/1,
        evidence_authorize_fn:
          &Threadline.OperatorSurface.RenderedOutputContractTest.Auth.authorize/1,
        export_authorize_fn:
          &Threadline.OperatorSurface.RenderedOutputContractTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.RenderedOutputContractTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_rendered_output_contract_key",
      signing_salt: "rendered-output"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.RenderedOutputContractTest.Router)
  end

  defmodule Threadline.OperatorSurface.RenderedOutputContractTest do
    @moduledoc false
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.RenderedOutputContractTest.Endpoint

    @planning_attributes ~w(data-earned-flow data-persona data-jtbd)
    @planning_vocabulary [
      {:phase, ~r/(?<![A-Za-z0-9])phase(?:[\s_-]+)?\d+(?![A-Za-z0-9])/i},
      {:milestone, ~r/(?<![A-Za-z0-9])milestone(?:[\s_-]+)?v?\d+(?:\.\d+)*(?![A-Za-z0-9])/i},
      {:decision, ~r/(?<![A-Za-z0-9])(?:decision[\s_-]*|D-)\d+(?![A-Za-z0-9])/i},
      {:requirement, ~r/(?<![A-Za-z0-9])(?:requirement[\s_-]*|REQ-)\d+(?![A-Za-z0-9])/i},
      {:owner_phase, ~r/(?<![A-Za-z0-9])owner[\s_-]*phase(?![A-Za-z0-9])/i},
      {:data, ~r/(?<![A-Za-z0-9])DATA[\s_-]*\d+(?![A-Za-z0-9])/i},
      {:earned_flow, ~r/(?<![A-Za-z0-9])EF\d+(?![A-Za-z0-9])/i},
      {:persona, ~r/(?<![A-Za-z0-9])P\d+(?![A-Za-z0-9])/i},
      {:job, ~r/(?<![A-Za-z0-9])J\d+(?![A-Za-z0-9])/i}
    ]

    # Sealed before the rendered-output edits begin. Plan 201-02 consumes these
    # structure-only receipts instead of accepting a replayed visual baseline.
    @pre_edit_receipts %{
      "start.record_lookup" => %{
        elements: 20,
        sha256: "f2434dc7348b02c0d74ea212cc6f8fd074b724d9b31f64ca5ce98235a10c3b87"
      },
      "start.correlation_lookup" => %{
        elements: 12,
        sha256: "a8ec0f2609ec9ec3493564f90e772008ab6e9284a2230635920cc2a1682cdb1b"
      },
      "exports.timeline_context" => %{
        elements: 45,
        sha256: "568e22a7119d9e5753bddabf42e4d92f9212f7241d4821aae9c52f8e9d84448a"
      },
      "exports.evidence_context" => %{
        elements: 42,
        sha256: "7a62c0f043c5c02b160d2fd45d3facc40f06ef2e94bb3834c2de62020b29c764"
      },
      "evidence.carry_to_exports" => %{
        elements: 1,
        sha256: "16250bb948aa1f2dcb3d36d78418c9b151fcf49fa5cb438c710588f2f8859810"
      },
      "row_history.shell" => %{
        elements: 114,
        sha256: "4994a628aaeb94eeb33ba105015bdfa05a36994316787f40a6d7f27dc838ebbf"
      },
      "timeline.carry_to_exports" => %{
        elements: 4,
        sha256: "eb676f68c6ff8f1073d2974ca829b9997a4695ad5734cc8ac2027dd676833c2a"
      }
    }
    @representative_node_ids @pre_edit_receipts |> Map.keys() |> Enum.sort()

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: String.duplicate("r", 64),
        live_view: [signing_salt: String.duplicate("r", 8)],
        render_errors: [view: Threadline.OperatorSurface.RenderedOutputContractTest.Layouts]
      )

      original_export_interval = Application.get_env(:threadline, :export_status_poll_ms)
      original_timeline_interval = Application.get_env(:threadline, :timeline_poll_ms)
      Application.put_env(:threadline, :export_status_poll_ms, 60_000)
      Application.put_env(:threadline, :timeline_poll_ms, 60_000)

      on_exit(fn ->
        restore_env(:export_status_poll_ms, original_export_interval)
        restore_env(:timeline_poll_ms, original_timeline_interval)
        Application.delete_env(:threadline, @endpoint)
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "tracked render-capable source inventory stays explicit and non-empty" do
      sources = owned_static_sources()

      assert sources == Enum.sort(sources)
      assert sources != []
      assert Enum.all?(sources, &String.valid?(File.read!(&1)))
      assert "lib/threadline/operator_surface/live/start_live.ex" in sources
      assert "lib/threadline/operator_surface/live/stress_live.ex" in sources
      assert "lib/threadline/operator_surface/stress_fixtures.ex" in sources
      assert "lib/threadline/operator_surface/style.ex" in sources
    end

    test "planning vocabulary matchers report actionable lines and honor token boundaries" do
      controls = """
      Phase 201
      milestone-v1.40
      D-08 and decision 9
      REQ-12 and requirement_13
      owner-phase DATA-02 EF3 P1 J6
      """

      offenders = scan_planning_vocabulary("positive-control", controls)

      assert MapSet.new(Enum.map(offenders, & &1.kind)) ==
               MapSet.new(Enum.map(@planning_vocabulary, &elem(&1, 0)))

      assert Enum.all?(offenders, fn offender ->
               offender.file == "positive-control" and offender.line > 0 and
                 is_binary(offender.match) and offender.match != ""
             end)

      assert scan_planning_vocabulary(
               "boundary-control",
               "xPhase 201 Phase 201x xEF3 EF3x AP1 P1x AJ6 J6x DATA-02x"
             ) == []
    end

    test "planning-attribute matcher is actionable without declaring the current output clean" do
      html = """
      <section data-earned-flow="EF3" data-persona='P3' data-jtbd="J6"></section>
      """

      assert Enum.map(scan_planning_attributes("positive-control", html), & &1.kind) ==
               Enum.map(@planning_attributes, &String.to_atom(String.replace(&1, "-", "_")))

      assert Enum.all?(scan_planning_attributes("positive-control", html), fn offender ->
               offender.file == "positive-control" and offender.line == 1 and
                 String.starts_with?(offender.match, "data-")
             end)

      assert scan_planning_attributes("clean-control", "<section data-state=\"ready\"></section>") ==
               []
    end

    test "exact seven-node representative inventory rejects incomplete sets and planning attributes",
         %{conn: conn} do
      inventory = representative_render_inventory(conn)

      assert map_size(inventory) == 7
      assert Map.keys(inventory) |> Enum.sort() == @representative_node_ids

      assert {:error, {:unexpected_inventory, []}} = validate_render_inventory(%{})

      incomplete = Map.delete(inventory, "timeline.carry_to_exports")

      assert {:error, {:unexpected_inventory, incomplete_ids}} =
               validate_render_inventory(incomplete)

      assert incomplete_ids ==
               Enum.reject(@representative_node_ids, &(&1 == "timeline.carry_to_exports"))

      clean_control_inventory =
        Map.new(@representative_node_ids, &{&1, "<section data-state=\"ready\"></section>"})

      for attribute <- @planning_attributes do
        seeded =
          Map.put(
            clean_control_inventory,
            "timeline.carry_to_exports",
            ~s(<a #{attribute}="seed" href="/audit/exports">Carry to Exports</a>)
          )

        expected_kind = String.to_atom(String.replace(attribute, "-", "_"))

        assert {:error,
                {:planning_attributes,
                 [%{file: "timeline.carry_to_exports", kind: ^expected_kind}]}} =
                 validate_render_inventory(seeded)
      end

      assert :ok = validate_render_inventory(inventory)
    end

    test "visible Threadline copy and Style.css comments contain no planning vocabulary", %{
      conn: conn
    } do
      inventory = representative_render_inventory(conn)

      visible_offenders =
        Enum.flat_map(inventory, fn {node_id, html} ->
          html
          |> LazyHTML.from_fragment()
          |> LazyHTML.to_tree()
          |> visible_text()
          |> scan_planning_vocabulary(node_id)
        end)

      fixture_offenders =
        Threadline.OperatorSurface.StressFixtures.all()
        |> Enum.flat_map(&Map.values/1)
        |> Enum.filter(&is_binary/1)
        |> Enum.join("\n")
        |> then(&scan_planning_vocabulary("Threadline.OperatorSurface.StressFixtures", &1))

      css = render_component(&Threadline.OperatorSurface.Style.css/1, [])

      assert visible_offenders == []
      assert fixture_offenders == []
      assert scan_css_provenance(css) == []

      # Host-supplied values are deliberately outside the static-copy corpus.
      assert [%{kind: :phase}] =
               scan_planning_vocabulary("host-data-control", "Customer note for Phase 201")
    end

    test "seven pre-edit structures have stable non-empty receipts", %{conn: conn} do
      receipts =
        conn
        |> representative_render_inventory()
        |> Map.new(fn {node_id, html} -> {node_id, structure_receipt(node_id, html)} end)

      assert Map.keys(receipts) |> Enum.sort() == Map.keys(@pre_edit_receipts) |> Enum.sort()
      assert Enum.all?(receipts, fn {_id, receipt} -> receipt.elements > 0 end)

      assert receipts == @pre_edit_receipts
    end

    test "canonical structure ignores copy and provenance but detects meaningful mutations" do
      baseline = """
      <a id="carry" class="tl-button primary" href="/audit/exports" role="button"
         aria-label="Carry" phx-click="carry"><span>Carry to Exports</span></a>
      """

      equivalent = """
      <a data-earned-flow="EF3" id="carry" class="primary tl-button"
         href="/audit/exports" role="button" aria-label="Carry" phx-click="carry">
        <span>Different copy</span>
      </a>
      """

      assert canonical_structure(baseline) == canonical_structure(equivalent)

      for mutation <- [
            String.replace(baseline, "<a ", "<button ") |> String.replace("</a>", "</button>"),
            String.replace(
              baseline,
              "<span>Carry to Exports</span>",
              "<div><span>Carry to Exports</span></div>"
            ),
            String.replace(baseline, "primary", "secondary"),
            String.replace(baseline, "id=\"carry\"", "id=\"deliver\""),
            String.replace(baseline, "/audit/exports", "/audit/timeline"),
            String.replace(baseline, "role=\"button\"", "role=\"link\""),
            String.replace(baseline, "aria-label=\"Carry\"", "aria-label=\"Deliver\""),
            String.replace(baseline, "phx-click=\"carry\"", "phx-click=\"deliver\"")
          ] do
        refute canonical_structure(baseline) == canonical_structure(mutation)
      end
    end

    test "release exception registry is empty by default and rejects unstable evidence" do
      assert :ok = validate_exception_registry([])

      valid = %{
        node_id: "start.record_lookup",
        before: 20,
        after: 21,
        delta: 1,
        rationale: "Measured exception approved for a bounded transition",
        expiry: "2026-10-01"
      }

      assert :ok = validate_exception_registry([valid])

      assert {:error, {:unknown_node_id, "Carry to Exports"}} =
               validate_exception_registry([%{valid | node_id: "Carry to Exports"}])

      assert {:error, {:delta_mismatch, "start.record_lookup"}} =
               validate_exception_registry([%{valid | delta: 2}])

      assert {:error, {:invalid_measurement, "start.record_lookup"}} =
               validate_exception_registry([%{valid | before: "20"}])

      assert {:error, {:invalid_rationale, "start.record_lookup"}} =
               validate_exception_registry([%{valid | rationale: ""}])

      assert {:error, {:invalid_expiry, "start.record_lookup"}} =
               validate_exception_registry([%{valid | expiry: "eventually"}])

      assert {:error, {:too_many_entries, 4}} =
               validate_exception_registry(List.duplicate(valid, 4))
    end

    defp owned_static_sources do
      {output, 0} =
        System.cmd("git", [
          "ls-files",
          "--",
          "lib/threadline/operator_surface/live/*.ex",
          "lib/threadline/operator_surface/stress_fixtures.ex",
          "lib/threadline/operator_surface/style.ex"
        ])

      output
      |> String.split("\n", trim: true)
      |> Enum.filter(&String.ends_with?(&1, ".ex"))
      |> Enum.sort()
    end

    defp validate_exception_registry(_entries), do: {:error, :not_implemented}

    defp representative_render_inventory(conn) do
      {:ok, _start, start_html} = live(conn, "/audit")

      {:ok, _timeline_export, timeline_export_html} =
        live(
          conn,
          "/audit/exports?table=ticket_replies&correlation_id=req_ef3&from=2026-05-01T00:00&to=2026-05-06T23:59"
        )

      subject_ref = URI.encode_www_form(Jason.encode!(%{"delivery_id" => "delivery-1"}))

      {:ok, _evidence_export, evidence_export_html} =
        live(
          conn,
          "/audit/exports?source=evidence&subject=export_delivery&mode=history&subject_ref_json=#{subject_ref}"
        )

      {:ok, _evidence, evidence_html} =
        live(conn, "/audit/evidence?subject=retention_run&mode=history")

      {:ok, _row_history, row_history_html} =
        live(
          conn,
          "/audit/rows/ticket_replies/render-contract-row?as_of=2026-05-03T12:00:00Z"
        )

      {:ok, _timeline, timeline_html} =
        live(
          conn,
          "/audit/timeline?from=2026-05-01T00:00&to=2026-05-06T23:59&table=ticket_replies&correlation_id=req_ef3"
        )

      start_panels = select_trees!(start_html, ".tl-home__earned-panel", 2)

      %{
        "start.record_lookup" => tree_html(Enum.at(start_panels, 0)),
        "start.correlation_lookup" => tree_html(Enum.at(start_panels, 1)),
        "exports.timeline_context" =>
          select_one!(timeline_export_html, ~s([data-testid="timeline-export-context"])),
        "exports.evidence_context" =>
          select_one!(evidence_export_html, ~s([data-testid="evidence-export-context"])),
        "evidence.carry_to_exports" => select_one!(evidence_html, ~s(a[href^="/audit/exports"])),
        "row_history.shell" => select_one!(row_history_html, ".threadline-ui"),
        "timeline.carry_to_exports" => select_one!(timeline_html, ~s(a[href^="/audit/exports?"]))
      }
    end

    defp scan_planning_vocabulary(file, content) when is_binary(content) do
      content
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_number} ->
        Enum.flat_map(@planning_vocabulary, fn {kind, pattern} ->
          Regex.scan(pattern, line, return: :binary)
          |> Enum.map(fn [match] ->
            %{file: file, kind: kind, line: line_number, match: match}
          end)
        end)
      end)
    end

    defp scan_planning_attributes(file, content) when is_binary(content) do
      content
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_number} ->
        Enum.flat_map(@planning_attributes, fn attribute ->
          pattern = ~r/#{Regex.escape(attribute)}\s*=\s*["'][^"']*["']/i

          Regex.scan(pattern, line, return: :binary)
          |> Enum.map(fn [match] ->
            %{
              file: file,
              kind: String.to_atom(String.replace(attribute, "-", "_")),
              line: line_number,
              match: match
            }
          end)
        end)
      end)
    end

    defp validate_render_inventory(inventory) when is_map(inventory) do
      actual_ids = inventory |> Map.keys() |> Enum.sort()

      if actual_ids == @representative_node_ids do
        offenders =
          Enum.flat_map(@representative_node_ids, fn node_id ->
            scan_planning_attributes(node_id, Map.fetch!(inventory, node_id))
          end)

        case offenders do
          [] -> :ok
          offenders -> {:error, {:planning_attributes, offenders}}
        end
      else
        {:error, {:unexpected_inventory, actual_ids}}
      end
    end

    defp scan_css_provenance(css) do
      Regex.scan(~r{/\*(.*?)\*/}s, css, return: :index)
      |> Enum.flat_map(fn [{comment_offset, comment_length}, {body_offset, body_length}] ->
        comment = binary_part(css, body_offset, body_length)
        starting_line = line_number_at(css, comment_offset)

        "Style.css/1"
        |> scan_planning_vocabulary(comment)
        |> Enum.map(&%{&1 | line: &1.line + starting_line - 1})
        |> Enum.map(&Map.put(&1, :comment_length, comment_length))
      end)
    end

    defp canonical_structure(html) do
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.to_tree(sort_attributes: true, skip_whitespace_nodes: true)
      |> canonical_nodes()
    end

    defp structure_receipt(node_id, html) do
      canonical = canonical_structure(html)

      %{
        elements: count_elements(canonical),
        sha256:
          :sha256
          |> :crypto.hash(:erlang.term_to_binary({node_id, canonical}))
          |> Base.encode16(case: :lower)
      }
    end

    defp canonical_nodes(nodes) when is_list(nodes) do
      Enum.flat_map(nodes, fn
        {tag, attributes, children} ->
          csrf_input? =
            tag == "input" and List.keyfind(attributes, "name", 0) == {"name", "_csrf_token"}

          normalized_attributes =
            attributes
            |> Enum.reject(fn {name, _value} -> name in @planning_attributes end)
            |> Enum.map(fn
              {"value", _value} when csrf_input? -> {"value", "<csrf-token>"}
              {"class", value} -> {"class", normalize_class(value)}
              attribute -> attribute
            end)
            |> Enum.sort()

          [{tag, normalized_attributes, canonical_nodes(children)}]

        _text_or_comment ->
          []
      end)
    end

    defp visible_text(nodes) when is_list(nodes) do
      nodes
      |> Enum.flat_map(fn
        {_tag, _attributes, children} -> [visible_text(children)]
        text when is_binary(text) -> [text]
        {:comment, _text} -> []
      end)
      |> Enum.join(" ")
    end

    defp count_elements(nodes) do
      Enum.reduce(nodes, 0, fn {_tag, _attributes, children}, count ->
        count + 1 + count_elements(children)
      end)
    end

    defp normalize_class(value) do
      value
      |> String.split()
      |> Enum.sort()
      |> Enum.join(" ")
    end

    defp select_one!(html, selector) do
      case select_trees!(html, selector, 1) do
        [tree] -> tree_html(tree)
      end
    end

    defp select_trees!(html, selector, expected_count) do
      trees =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(selector)
        |> LazyHTML.to_tree(sort_attributes: true, skip_whitespace_nodes: true)

      assert length(trees) == expected_count,
             "expected #{expected_count} nodes for #{inspect(selector)}, got #{length(trees)}"

      trees
    end

    defp tree_html(tree) do
      [tree]
      |> LazyHTML.from_tree()
      |> LazyHTML.to_html()
    end

    defp line_number_at(content, offset) do
      content
      |> binary_part(0, offset)
      |> String.split("\n")
      |> length()
    end

    defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
    defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
  end
end
