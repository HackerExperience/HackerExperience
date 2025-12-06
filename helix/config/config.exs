import Config

read_env_file = fn path ->
  if File.exists?(path) do
    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.each(fn line ->
      case String.split(line, "=", parts: 2) do
        [key, value] -> System.put_env(key, value)
        _ -> :noop
      end
    end)
  end
end

# Source the .env/.local.env files
Enum.each([".env", ".local.env"], read_env_file)

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
