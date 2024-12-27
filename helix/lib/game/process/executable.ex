defmodule Game.Process.Executable do
  alias Game.Services, as: Svc

  def execute(process_mod, server_id, entity_id, params, meta) do
    executable = get_executable(process_mod)
    callbacks = get_implemented_callbacks(executable)
    args = [server_id, entity_id, params, meta]
    {registry_data, process_info} = get_params(executable, args, callbacks)

    case Svc.Process.create(server_id, entity_id, registry_data, process_info) do
      {:ok, process, events} ->
        {:ok, process, events}

      {:error, reason} ->
        raise "Failed to execute process: #{inspect(reason)}"
    end
  end

  defp get_params(executable, args = [_, _, params, meta], callbacks) do
    # Custom pre-hook
    custom = callback(executable, :custom, args, callbacks)
    args = args ++ [custom]

    target_log = callback(executable, :target_log, args, callbacks)

    # TODO: Executable.resources actually
    resources_params = [meta]
    resources = get_resources(executable, resources_params)

    process_data = get_process_data(executable, params, meta)
    process_type = get_process_type(executable, params, meta)
    process_info = {process_type, process_data}

    registry_data =
      %{}
      |> Map.merge(target_log)
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
