defmodule Game.Process.Executable do
  require Logger
  alias Game.Services, as: Svc

  # NOTE/TODO: At the moment, I fail to see a reason for having both `params` and `meta`. Why not
  # merge them in a single variable? Merge them or document why the decoupling is necessary.
  def execute(process_mod, server_id, entity_id, params, meta) do
    executable = get_executable(process_mod)
    args = [server_id, entity_id, params, meta]
    {registry_data, process_info} = get_registry_params(executable, args)

    case Svc.Process.create(server_id, entity_id, registry_data, process_info) do
      {:ok, process, events} ->
        {:ok, process, events}

      {:error, reason} ->
        Logger.error("Failed to execute process: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  This function is public for test utils; but within the scope of this module (and of any production
  code) it is private.
  """
  def get_registry_params(executable, args = [_, _, params, meta]) do
    callbacks = get_implemented_callbacks(executable)

    # Custom pre-hook
    custom = callback(executable, :custom, args, callbacks)
    args = args ++ [custom]

    source_file = callback(executable, :source_file, args, callbacks)
    target_file = callback(executable, :target_file, args, callbacks)
    target_log = callback(executable, :target_log, args, callbacks)

    resources_params = [[params, meta]]
    resources = get_resources(executable, resources_params)

    process_data = get_process_data(executable, params, meta)
    process_type = get_process_type(executable, params, meta)
    process_info = {process_type, process_data}

    registry_data =
      %{}
      |> Map.merge(target_log)
      |> Map.merge(source_file)
      |> Map.merge(target_file)
      |> Map.merge(resources)

    {registry_data, process_info}
  end

  defp get_resources(executable, params),
    do: call_process(executable, :resources, params)

  defp callback(executable, method, args, callbacks) do
    result =
      if Keyword.has_key?(callbacks, method) do
        apply(executable, method, args)
      else
        apply(__MODULE__.Defaults, method, args)
      end

    __MODULE__.Formatter.format(method, result)
  end

  defp get_process_data(executable, params, meta),
    do: call_process(executable, :new, [params, meta])

  defp get_process_type(_, _, %{type: process_type}), do: process_type

  defp get_process_type(executable, params, meta),
    do: call_process(executable, :get_process_type, [params, meta])

  defp call_process(executable, method, args) do
    executable
    |> get_process_module()
    |> apply(method, args)
  end

  defp get_process_module(executable) do
    executable
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end

  defp get_executable(process),
    do: Module.concat(process, :Executable)

  defp get_implemented_callbacks(executable),
    do: executable.__info__(:functions)
end
