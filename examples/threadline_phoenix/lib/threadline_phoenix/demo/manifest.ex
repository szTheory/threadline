defmodule ThreadlinePhoenix.Demo.Manifest do
  @moduledoc """
  Single source of truth for walkthrough literals (orgs, tickets, users, time anchors).

  Org and user ids are UUID v5 under namespace `"threadline.demo"` (DNS namespace →
  `threadline.demo` → per-entity names like `org/acme` or `user/closer@acme.example.com`).
  See `examples/threadline_phoenix/DEMO-MANIFEST.md` for the human-readable contract.

  `demo_last_tuesday` is the absolute UTC instant for operator filters when walkthrough
  prose says “last Tuesday” — derived as seven days before `demo_epoch` at 14:30 UTC
  (2026-05-20, a Tuesday relative to epoch 2026-05-27).
  """

  defmodule UUID do
    @moduledoc false
    @dns <<107, 167, 184, 16, 157, 173, 17, 209, 128, 180, 0, 192, 79, 212, 48, 200>>

    def dns_namespace, do: @dns

    def v5(namespace_bin, name)
        when is_binary(namespace_bin) and byte_size(namespace_bin) == 16 do
      namespace_bin
      |> v5_binary(name)
      |> format()
    end

    def v5_binary(namespace_bin, name)
        when is_binary(namespace_bin) and byte_size(namespace_bin) == 16 do
      <<
        time_low::32,
        time_mid::16,
        time_hi_and_version::16,
        clock_seq_hi_and_reserved::8,
        clock_seq_low::8,
        node::48
      >> =
        namespace_bin
        |> then(&:crypto.hash(:sha, &1 <> name))
        |> binary_part(0, 16)

      time_hi_and_version = Bitwise.bor(Bitwise.band(time_hi_and_version, 0x0FFF), 0x5000)

      clock_seq_hi_and_reserved =
        Bitwise.bor(Bitwise.band(clock_seq_hi_and_reserved, 0x3F), 0x80)

      <<
        time_low::32,
        time_mid::16,
        time_hi_and_version::16,
        clock_seq_hi_and_reserved::8,
        clock_seq_low::8,
        node::48
      >>
    end

    def format(<<a::32, b::16, c::16, d::16, e::48>> = uuid) when byte_size(uuid) == 16 do
      :io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [a, b, c, d, e])
      |> IO.iodata_to_binary()
    end
  end

  @demo_epoch ~U[2026-05-27 12:00:00Z]
  @demo_last_tuesday ~U[2026-05-20 14:30:00Z]

  @hero_close_number 4521
  @hero_delete_number 4518

  @correlation_acme_close "walk-acme-4521-close"
  @evidence_run_offboarded "walk-retention-offboarded-co"
  @evidence_retention_policy_ref %{"policy" => "walk-demo-retention-policy"}
  @evidence_redaction_policy_ref %{"policy" => "walk-demo-redaction-policy"}
  @evidence_trigger_coverage_ref %{"snapshot" => "walk-demo-trigger-coverage"}

  @org_slugs [:acme, :globex, :offboarded_co]

  @org_slug_strings %{
    acme: "acme",
    globex: "globex",
    offboarded_co: "offboarded-co"
  }

  @user_emails %{
    closer: "closer@acme.example.com",
    deleter: "deleter@acme.example.com",
    admin: "admin@example.com",
    support_acme: "support@acme.example.com",
    support_globex: "support@globex.example.com",
    support_offboarded: "support@offboarded-co.example.com"
  }

  @demo_namespace_bin UUID.v5_binary(UUID.dns_namespace(), "threadline.demo")

  @org_ids for slug <- @org_slugs,
               into: %{},
               do:
                 {slug,
                  UUID.format(
                    UUID.v5_binary(
                      @demo_namespace_bin,
                      "org/#{Map.fetch!(@org_slug_strings, slug)}"
                    )
                  )}

  @user_ids for {key, email} <- @user_emails,
                into: %{},
                do: {key, UUID.format(UUID.v5_binary(@demo_namespace_bin, "user/#{email}"))}

  @ticket_numbers %{
    hero_close: @hero_close_number,
    hero_delete: @hero_delete_number
  }

  @doc "Frozen demo “today” for timeline backfill and filters."
  def epoch, do: @demo_epoch

  @doc "Absolute UTC for walkthrough “last Tuesday” operator filters."
  def last_tuesday, do: @demo_last_tuesday

  @doc "Deterministic organization id (`:acme`, `:globex`, `:offboarded_co`)."
  def org_id(slug) when slug in @org_slugs, do: Map.fetch!(@org_ids, slug)

  @doc "Slug string for an org atom, or reverse lookup from org uuid."
  def org_slug(slug) when slug in @org_slugs, do: Map.fetch!(@org_slug_strings, slug)

  def org_slug(org_uuid) when is_binary(org_uuid) do
    Enum.find_value(@org_ids, fn {slug, id} -> if id == org_uuid, do: slug end)
  end

  @doc "Hero ticket numbers (`:hero_close` → 4521, `:hero_delete` → 4518)."
  def ticket_number(key) when key in [:hero_close, :hero_delete],
    do: Map.fetch!(@ticket_numbers, key)

  @doc "Sigra user email for a persona key."
  def user_email(key) when is_atom(key), do: Map.fetch!(@user_emails, key)

  @doc "Deterministic Sigra user id (UUID string) for a persona key."
  def user_id(key) when is_atom(key), do: Map.fetch!(@user_ids, key)

  @doc "Semantic correlation id for anchor incidents."
  def correlation_id(:acme_4521_close), do: @correlation_acme_close

  @doc "Fixed evidence run id for org Y retention walkthrough proof."
  def evidence_run_id(:offboarded_retention), do: @evidence_run_offboarded

  @doc "Fixed evidence `subject_ref` for retention, redaction, and trigger coverage snapshots."
  def evidence_subject_ref(:retention_policy), do: @evidence_retention_policy_ref

  def evidence_subject_ref(:redaction_policy), do: @evidence_redaction_policy_ref

  def evidence_subject_ref(:trigger_coverage), do: @evidence_trigger_coverage_ref

  @doc "Demo password for seeded Sigra users (overridable via app env or `DEMO_SEED_PASSWORD`)."
  def demo_seed_password do
    System.get_env("DEMO_SEED_PASSWORD") ||
      Application.get_env(:threadline_phoenix, :demo_seed_password, "password123456")
  end

  @doc false
  def org_ids, do: @org_ids

  @doc false
  def user_ids, do: @user_ids
end
