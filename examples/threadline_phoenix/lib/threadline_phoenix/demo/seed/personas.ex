defmodule ThreadlinePhoenix.Demo.Seed.Personas do
  @moduledoc false

  alias ThreadlinePhoenix.Accounts.User
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Demo.Manifest.UUID
  alias ThreadlinePhoenix.Demo.Seed.Support
  alias ThreadlinePhoenix.HelpDesk.{Agent, OrgMembership, Organization}
  alias ThreadlinePhoenix.Repo

  @demo_namespace_bin UUID.v5_binary(UUID.dns_namespace(), "threadline.demo")

  @extra_personas [
    {:agent2, "agent2@acme.example.com", :acme},
    {:agent3, "agent3@acme.example.com", :acme},
    {:agent4, "agent4@globex.example.com", :globex},
    {:agent5, "agent5@globex.example.com", :globex},
    {:agent6, "agent6@offboarded-co.example.com", :offboarded_co},
    {:agent7, "agent7@offboarded-co.example.com", :offboarded_co}
  ]

  @org_specs [
    {:acme, "Acme", [:closer, :deleter, :support_acme, :agent2, :agent3]},
    {:globex, "Globex", [:support_globex, :agent4, :agent5]},
    {:offboarded_co, "Offboarded Co", [:support_offboarded, :agent6, :agent7]}
  ]

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    password = Manifest.demo_seed_password()
    orgs = upsert_orgs()
    users = upsert_users(password)
    users = upsert_extra_users(users, password)
    ctx = Map.merge(ctx, %{orgs: orgs, users: users})
    seed_memberships(ctx)
  end

  defp upsert_orgs do
    Map.new(@org_specs, fn {slug, name, _} ->
      id = Manifest.org_id(slug)

      org =
        %Organization{id: id}
        |> Organization.changeset(%{slug: Manifest.org_slug(slug), name: name})
        |> Repo.insert!(
          on_conflict: {:replace, [:slug, :name, :updated_at]},
          conflict_target: :id
        )

      {slug, org}
    end)
  end

  defp upsert_users(password) do
    Manifest.user_ids()
    |> Enum.map(fn {key, _id} ->
      email = Manifest.user_email(key)
      user = upsert_user!(email, Manifest.user_id(key), password)
      {key, user}
    end)
    |> Map.new()
  end

  defp upsert_extra_users(users, password) do
    Enum.reduce(@extra_personas, users, fn {key, email, _org}, acc ->
      user_id = UUID.format(UUID.v5_binary(@demo_namespace_bin, "user/#{email}"))
      Map.put(acc, key, upsert_user!(email, user_id, password))
    end)
  end

  defp upsert_user!(email, fixed_id, password) do
    case Repo.get_by(User, email: email) do
      %User{id: id} = user ->
        if to_string(id) != fixed_id do
          raise "demo seed user #{email} exists with unexpected id #{id}, expected #{fixed_id}"
        end

        maybe_confirm!(user)

      nil ->
        %User{id: fixed_id}
        |> User.registration_changeset(%{email: email, password: password})
        |> Repo.insert!()
        |> maybe_confirm!()
    end
  end

  defp maybe_confirm!(%User{confirmed_at: nil} = user) do
    user
    |> User.confirm_changeset()
    |> Repo.update!()
  end

  defp maybe_confirm!(user), do: user

  defp seed_memberships(ctx) do
    admin_id = to_string(Map.fetch!(ctx.users, :admin).id)
    setup_ts = DateTime.add(Manifest.epoch(), -21, :day)

    ctx =
      Enum.reduce(Map.keys(ctx.orgs), ctx, fn org_slug, acc ->
        org = Map.fetch!(acc.orgs, org_slug)

        {:ok, tx_id} =
          Repo.transaction(fn ->
            Support.set_actor_guc!(admin_id, :admin)
            ensure_membership!(org, admin_id, "support")
            ensure_agent!(org, admin_id, "Admin")
            Support.current_audit_transaction_id()
          end)

        if tx_id, do: Support.put_timestamp(acc, tx_id, setup_ts), else: acc
      end)

    Enum.reduce(@org_specs, ctx, fn {org_slug, _name, persona_keys}, acc ->
      org = Map.fetch!(acc.orgs, org_slug)

      Enum.reduce(persona_keys, acc, fn key, inner_acc ->
        user = Map.fetch!(inner_acc.users, key)
        user_id = to_string(user.id)

        role =
          if key in [:support_acme, :support_globex, :support_offboarded],
            do: "support",
            else: "agent"

        {:ok, tx_id} =
          Repo.transaction(fn ->
            Support.set_actor_guc!(admin_id, :admin)
            ensure_membership!(org, user_id, role)
            ensure_agent!(org, user_id, display_name(key))
            Support.current_audit_transaction_id()
          end)

        if tx_id, do: Support.put_timestamp(inner_acc, tx_id, setup_ts), else: inner_acc
      end)
    end)
  end

  defp ensure_membership!(%Organization{} = org, user_id, role) do
    case Repo.get_by(OrgMembership, organization_id: org.id, user_id: user_id) do
      %OrgMembership{} = membership ->
        membership

      nil ->
        %OrgMembership{organization_id: org.id, user_id: user_id}
        |> OrgMembership.changeset(%{role: role})
        |> Repo.insert!()
    end
  end

  defp ensure_agent!(%Organization{} = org, user_id, display_name) do
    case Repo.get_by(Agent, organization_id: org.id, user_id: user_id) do
      %Agent{} = agent ->
        agent

      nil ->
        %Agent{organization_id: org.id, user_id: user_id}
        |> Agent.changeset(%{display_name: display_name})
        |> Repo.insert!()
    end
  end

  defp display_name(:closer), do: "Acme Closer"
  defp display_name(:deleter), do: "Acme Deleter"
  defp display_name(:support_acme), do: "Acme Support"
  defp display_name(:support_globex), do: "Globex Support"
  defp display_name(:support_offboarded), do: "Offboarded Support"

  defp display_name(key) when is_atom(key),
    do: key |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
end
