defmodule ThreadlinePhoenix.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :failed_login_attempts, :integer, default: 0
    field :locked_at, :utc_datetime
    field :password_changed_at, :utc_datetime

    # Account lifecycle fields (Phase 8)
    field :pending_email, :string
    field :deleted_at, :utc_datetime
    field :scheduled_deletion_at, :utc_datetime
    field :original_email, :string
    field :must_change_password, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  A changeset for registering a new user.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    # Add custom fields here (e.g., :name, :company)
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> update_change(:email, &Sigra.Email.normalize/1)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> Sigra.PasswordPolicy.validate()
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Sigra.Crypto.hash_password(password))
      |> put_change(:password_changed_at, DateTime.utc_now() |> DateTime.truncate(:second))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, ThreadlinePhoenix.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A changeset for changing the user email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A changeset for changing the user password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Validates the current password when changing the user password.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  A changeset for setting/clearing the pending email during email change flow.
  """
  def pending_email_changeset(user, attrs) do
    user
    |> cast(attrs, [:pending_email])
    |> validate_format(:pending_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> unsafe_validate_unique(:pending_email, ThreadlinePhoenix.Repo)
    |> unique_constraint(:pending_email)
  end

  @doc """
  A changeset for account deletion lifecycle fields.
  """
  def deletion_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :deleted_at,
      :scheduled_deletion_at,
      :original_email,
      :pending_email,
      :email,
      :hashed_password
    ])
  end

  @doc """
  A changeset for the must_change_password flag.
  """
  def force_password_changeset(user, attrs) do
    user
    |> cast(attrs, [:must_change_password])
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Sigra.Crypto.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%__MODULE__{hashed_password: hashed_password} = _user, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Sigra.Crypto.verify_password(password, hashed_password)
  end

  def valid_password?(_, _) do
    Sigra.Crypto.no_user_verify()
  end
end
