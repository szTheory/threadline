defmodule ThreadlinePhoenix.AccountsFixtures do
  @moduledoc """
  Test fixtures for authentication.

  This module provides helper functions for creating test users
  and extracting tokens from delivery functions.
  """

  import Phoenix.ConnTest, only: [build_conn: 0]
  import ThreadlinePhoenixWeb.ConnCaseHelpers, only: [log_in_user: 2]

  alias ThreadlinePhoenix.Accounts

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "password123456"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> ThreadlinePhoenix.Accounts.register_user()

    user
    |> ThreadlinePhoenix.Accounts.User.confirm_changeset()
    |> ThreadlinePhoenix.Repo.update!()
  end

  def extract_user_token(fun) do
    {:ok, captured_token} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_token, "[TOKEN]")
    token
  end

  @doc """
  Creates a standard session for the given user.

  Accepts optional attributes to override defaults (e.g., `:ip`, `:user_agent`, `:type`).
  """
  def session_fixture(user, attrs \\ %{}) do
    token = :crypto.strong_rand_bytes(32)
    hashed_token = :crypto.hash(:sha256, token)

    now = DateTime.utc_now()

    defaults = %{
      hashed_token: hashed_token,
      type: "standard",
      ip: "127.0.0.1",
      user_agent: "ExUnit/1.0",
      last_active_at: now,
      inserted_at: now
    }

    session_attrs = Map.merge(defaults, attrs)

    %ThreadlinePhoenix.Accounts.UserSession{}
    |> Ecto.Changeset.change(Map.put(session_attrs, :user_id, user.id))
    |> ThreadlinePhoenix.Repo.insert!()
  end

  @doc """
  Creates a remember-me session for the given user.
  """
  def remembered_session_fixture(user, attrs \\ %{}) do
    session_fixture(user, Map.put(attrs, :type, "remember_me"))
  end

  @doc """
  Creates an organization row for tests.

  This helper accelerates unit and integration setup, but it can bypass real
  controller behavior, bypass real LiveView behavior, and bypass real session
  boundaries. Keep route-backed coverage for organization creation and
  switching flows.
  """
  def create_organization(attrs \\ %{}) do
    organization_module = ensure_generated_module!(:Organization)

    defaults = %{
      name: "Organization #{System.unique_integer([:positive])}",
      slug: "organization-#{System.unique_integer([:positive])}"
    }

    attrs = Enum.into(attrs, defaults)

    organization_module
    |> struct()
    |> organization_module.changeset(attrs)
    |> ThreadlinePhoenix.Repo.insert!()
  end

  @doc """
  Creates a membership row for the given user and organization.

  This helper can bypass real controller behavior, bypass real LiveView
  behavior, and bypass real session boundaries so tests can stage org-aware
  data quickly. Keep route-backed authorization coverage for membership writes
  and active-organization changes.
  """
  def create_membership(user, organization, role \\ :owner) do
    membership_module = ensure_generated_module!(:OrganizationMembership)

    membership_module
    |> struct()
    |> membership_module.changeset(%{
      user_id: user.id,
      organization_id: organization.id,
      role: role
    })
    |> ThreadlinePhoenix.Repo.insert!()
  end

  @doc """
  Logs a user into a conn with an active organization staged on the session.

  This helper can bypass real controller behavior, bypass real LiveView
  behavior, and bypass real session boundaries to speed up focused tests. Keep
  route-backed coverage for login, org switching, and scope hydration
  behavior.
  """
  def log_in_user_with_org(conn, user, organization) do
    membership =
      ThreadlinePhoenix.Repo.get_by(ensure_generated_module!(:OrganizationMembership),
        user_id: user.id,
        organization_id: organization.id
      ) || create_membership(user, organization)

    token = ThreadlinePhoenix.Accounts.generate_user_session_token(user)
    {_authed_user, session} = ThreadlinePhoenix.Accounts.get_user_and_session_by_token(token)

    {:ok, session} =
      session
      |> Ecto.Changeset.change(%{active_organization_id: organization.id})
      |> ThreadlinePhoenix.Repo.update()

    scope =
      ensure_generated_module!(:Scope)
      |> apply(:for_user, [user])
      |> apply(:put_active_organization, [organization, membership])

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.assign(:current_scope, scope)
    |> Plug.Conn.put_private(:sigra_session, session)
  end

  @doc """
  Creates a passkey credential row for the given user.

  This helper can bypass real controller behavior, bypass real LiveView
  behavior, and bypass real session boundaries before the browser ceremony. Use
  route-backed tests for actual WebAuthn registration flows.
  """
  def register_passkey(user, attrs \\ %{}) do
    passkey_module = ensure_generated_module!(:UserPasskey)
    now = DateTime.utc_now()

    defaults = %{
      id: Ecto.UUID.generate(),
      user_id: user.id,
      credential_id: "credential-" <> Integer.to_string(System.unique_integer([:positive])),
      public_key: <<1, 2, 3, 4>>,
      sign_count: 0,
      aaguid: "00000000-0000-0000-0000-000000000000",
      nickname: "Test passkey",
      device_hint: "Test Device",
      transports: ["internal"],
      rp_id: "localhost",
      last_used_at: nil,
      inserted_at: now,
      updated_at: now
    }

    attrs = Enum.into(attrs, defaults)

    passkey_module
    |> struct(attrs)
    |> ThreadlinePhoenix.Repo.insert!()
  end

  @doc """
  Builds deterministic passkey authentication test data.

  This helper can bypass real controller behavior, bypass real LiveView
  behavior, and bypass real session boundaries so focused tests can stage a
  passkey assertion quickly. Keep route-backed coverage for end-to-end passkey
  sign-in and MFA flows.
  """
  def authenticate_with_passkey(user, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    passkey = Map.get(attrs, :passkey) || register_passkey(user, attrs)

    %{
      user: user,
      passkey: passkey,
      response:
        encoded_passkey_response(%{
          credential_id: passkey.credential_id,
          user_handle: user.id
        })
    }
  end

  @doc """
  Locks the given user by setting failed login attempts and locked_at.
  """
  def locked_user_fixture(user) do
    user
    |> Ecto.Changeset.change(%{
      failed_login_attempts: 5,
      locked_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> ThreadlinePhoenix.Repo.update!()
  end

  @doc """
  Creates a session with sudo mode activated for the given user.
  """
  def sudo_session_fixture(user, attrs \\ %{}) do
    session = session_fixture(user, Map.put(attrs, :sudo_at, DateTime.utc_now()))
    session
  end

  @doc """
  Creates a user with MFA (TOTP) enabled.

  Returns `%{user: user, totp_secret: secret, backup_codes: codes}` where
  `secret` is the raw Base32 TOTP secret and `codes` are the plaintext
  backup codes (before hashing).
  """
  def mfa_user_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    config = Accounts.sigra_config()

    %{secret: secret, backup_codes: codes} =
      Sigra.Testing.setup_totp(user,
        config: config,
        mfa_credential_schema: ThreadlinePhoenix.Accounts.UserMFACredential,
        backup_code_schema: ThreadlinePhoenix.Accounts.UserBackupCode
      )

    %{user: user, totp_secret: secret, backup_codes: codes}
  end

  @doc """
  Creates a user with MFA enabled and an `mfa_pending` session.

  Returns `%{user: user, session: session, totp_secret: secret}`.
  """
  def mfa_pending_session_fixture(attrs \\ %{}) do
    %{user: user, totp_secret: secret} = mfa_user_fixture(attrs)
    session = session_fixture(user, %{type: "mfa_pending"})
    %{user: user, session: session, totp_secret: secret}
  end

  @doc """
  Creates a user with MFA enabled whose MFA credential is locked out
  (failed_attempts >= threshold).

  Returns `%{user: user, credential: credential}`.
  """
  def mfa_locked_fixture(attrs \\ %{}) do
    %{user: user} = mfa_user_fixture(attrs)
    config = Accounts.sigra_config()

    credential =
      Sigra.Testing.simulate_mfa_lockout(user,
        config: config,
        mfa_credential_schema: ThreadlinePhoenix.Accounts.UserMFACredential
      )

    %{user: user, credential: credential}
  end

  # -- Account Lifecycle Fixtures (Phase 8) --

  @doc """
  Creates a user with account deletion scheduled.

  Returns the user with `deleted_at` and `scheduled_deletion_at` set.

  ## Options

    * `:grace_period_days` - Days until permanent deletion (default: 14)
  """
  def scheduled_deletion_fixture(attrs \\ %{}, opts \\ []) do
    user = user_fixture(attrs)

    Sigra.Testing.scheduled_deletion_fixture(
      ThreadlinePhoenix.Repo,
      user,
      opts
    )
  end

  @doc """
  Creates a user with the force password change flag set.

  Returns the user with `must_change_password: true`.
  """
  def force_password_change_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    Sigra.Testing.force_password_change_fixture(
      ThreadlinePhoenix.Repo,
      user
    )
  end

  # --- Scenario Fixtures (Phase 10, DX-03) ---
  #
  # Named wrappers composing the primitives above. Each returns a
  # non-uniform map containing only the keys the scenario needs (D-04).
  # Scenarios representing pre-login or blocked state (mfa_pending,
  # locked, unconfirmed) deliberately omit :conn (D-07).
  #
  # These are UNIT-level helpers — they bypass real CSRF, rate limiting,
  # and session-renewal flows. Integration tests exercising auth gates
  # must drive real register/log_in controllers, not these fixtures.

  @doc """
  Anonymous / unauthenticated scenario. Returns a fresh conn with no
  session.
  """
  def anonymous_fixture do
    %{conn: build_conn()}
  end

  @doc """
  Authenticated scenario. Returns user, session, and a logged-in conn.
  """
  def authenticated_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    session = session_fixture(user)
    %{user: user, session: session, conn: log_in_user(build_conn(), user)}
  end

  @doc """
  MFA-pending scenario. User has TOTP enrolled; session type is
  `"mfa_pending"`. Caller has NOT yet passed the challenge, so no
  `:conn` is returned (D-07).
  """
  def mfa_pending_fixture(attrs \\ %{}) do
    mfa_pending_session_fixture(attrs)
  end

  @doc """
  MFA-complete scenario. User has TOTP enrolled AND has passed the
  challenge.

  Phase 6 transitions the session type from `"mfa_pending"` to
  `"standard"` on successful verification rather than stamping a
  separate timestamp; this fixture therefore returns a post-transition
  standard session. Represents post-verification state only — real MFA
  gate behavior is verified by integration tests that drive the
  challenge controller.
  """
  def mfa_complete_fixture(attrs \\ %{}) do
    %{user: user, totp_secret: secret} = mfa_user_fixture(attrs)
    session = session_fixture(user, %{type: "standard"})
    conn = log_in_user(build_conn(), user)
    %{user: user, session: session, conn: conn, totp_secret: secret}
  end

  @doc """
  Sudo scenario. Authenticated user whose session has a recent
  `sudo_at`, suitable for testing sensitive operations that require
  sudo mode.
  """
  def sudo_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    session = sudo_session_fixture(user)
    %{user: user, session: session, conn: log_in_user(build_conn(), user)}
  end

  @doc """
  Locked scenario. User with `failed_login_attempts == 5` and
  `locked_at` set. No `:conn` — locked users cannot log in (D-07).
  """
  def locked_fixture(attrs \\ %{}) do
    user = attrs |> user_fixture() |> locked_user_fixture()
    %{user: user}
  end

  @doc """
  Unconfirmed scenario. User exists but `confirmed_at` is nil (email
  not yet confirmed per D-06). No `:conn` (D-07).
  """
  def unconfirmed_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    %{user: user}
  end

  # Canonical list of valid scenario atoms. Lives next to its consumer
  # (scenario/2) so the error message stays in sync with the clauses.
  @valid_scenarios [
    :anonymous,
    :authenticated,
    :mfa_pending,
    :mfa_complete,
    :sudo,
    :locked,
    :unconfirmed
  ]

  @doc """
  Dispatcher for parametric test setup. Accepts one of:
  `:anonymous | :authenticated | :mfa_pending | :mfa_complete | :sudo | :locked | :unconfirmed`.

  Raises `ArgumentError` (with the full list of valid scenarios in the
  message) on unknown atoms. Raises `FunctionClauseError` on non-atom
  input — passing a string is a clear caller bug and the
  FunctionClauseError preserves that signal.
  """
  def scenario(name, attrs \\ %{})
  def scenario(:anonymous, _attrs), do: anonymous_fixture()
  def scenario(:authenticated, attrs), do: authenticated_fixture(attrs)
  def scenario(:mfa_pending, attrs), do: mfa_pending_fixture(attrs)
  def scenario(:mfa_complete, attrs), do: mfa_complete_fixture(attrs)
  def scenario(:sudo, attrs), do: sudo_fixture(attrs)
  def scenario(:locked, attrs), do: locked_fixture(attrs)
  def scenario(:unconfirmed, attrs), do: unconfirmed_fixture(attrs)

  def scenario(other, _attrs) when is_atom(other) do
    raise ArgumentError, """
    unknown scenario #{inspect(other)}.

    Valid scenarios: #{Enum.map_join(@valid_scenarios, ", ", &inspect/1)}.
    """
  end

  defp encoded_passkey_response(attrs) do
    credential_id =
      Map.get(attrs, :credential_id) || Map.get(attrs, "credential_id") || "credential-response"

    encoded_credential_id = base64url(credential_id)
    user_handle = Map.get(attrs, :user_handle) || Map.get(attrs, "user_handle")

    response =
      %{
        "clientDataJSON" => base64url(~s({"type":"webauthn.get","challenge":"test"})),
        "authenticatorData" => base64url("authenticator-data"),
        "signature" => base64url("signature"),
        "userHandle" => if(user_handle, do: base64url(to_string(user_handle)), else: nil),
        "attestationObject" => base64url("attestation-object"),
        "transports" => ["internal"]
      }
      |> Map.reject(fn {_key, value} -> is_nil(value) end)

    %{
      "id" => encoded_credential_id,
      "rawId" => encoded_credential_id,
      "type" => "public-key",
      "response" => response
    }
    |> JSON.encode!()
  end

  defp ensure_generated_module!(suffix) do
    module = Module.concat(ThreadlinePhoenix.Accounts, suffix)

    if Code.ensure_loaded?(module) do
      module
    else
      raise ArgumentError,
        "AuthFixtures.#{Macro.underscore(to_string(suffix))} requires #{inspect(module)}. " <>
          "Generate organizations/passkeys or keep route-backed coverage for that feature."
    end
  end

  defp base64url(value) when is_binary(value), do: Base.url_encode64(value, padding: false)
end
