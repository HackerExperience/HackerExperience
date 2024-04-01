defmodule Core.Crypto.Password do
  require Logger

  # TODO: Move to a runtime config
  @pepper "todo_pepper_goes_here"
  @hash_prefix "$argon2id$v=19$m="

  def generate_hash(raw_password) do
    case __MODULE__.Argon2.hash(@pepper, raw_password) do
      {:ok, hashed_password} ->
        true = String.starts_with?(hashed_password, @hash_prefix)
        {:ok, hashed_password}

      {:error, reason} ->
        Logger.error("Failed to generate password hash: #{reason}")
        {:error, reason}
    end
  end

  def generate_hash!(raw_password) do
    {:ok, hashed_password} = generate_hash(raw_password)
    hashed_password
  end

  def verify_hash(hashed_password, raw_password) do
    case __MODULE__.Argon2.verify(@pepper, raw_password, hashed_password) do
      {:ok, _} ->
        true

      {:error, "invalid password"} ->
        false

      {:error, reason} ->
        Logger.error("Failed to verify password hash: #{reason}")
        false
    end
  end

  def dummy_hash do
    # TODO: Generate it on system startup
    # (So it's guaranteed to use the "actual" pepper, regardless of env)
    "$argon2id$v=19$m=1024,t=1,p=1$pnXzkMn8qbdDVtdx21KTPQ$5m+b4Fhq7kHiuxcO1wHgRhv+dVrYb1nT1IRz0dN9o3U"
  end
end
