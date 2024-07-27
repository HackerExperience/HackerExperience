defmodule Webserver.Conveyor do
  @moduledoc """
  NOTE: This could be moved to its own library.
  """

  defstruct [:halt?, :trace, :response_status, :response_message]

  alias __MODULE__

  def new do
    %__MODULE__{
      halt?: false,
      response_status: nil,
      response_message: nil,
      trace: []
    }
  end

  def execute(request, belts) when is_list(belts) do
    # TODO: Maybe change this so that Entrypoint is executed automatically from within `execute/2`
    belts = [Conveyor.Belts.Entrypoint | belts]

    Enum.reduce_while(belts, request, fn belt, request_acc ->
      {belt_module, belt_params} =
        case belt do
          {mod, params} -> {mod, params}
          {mod} -> {mod, nil}
          mod -> {mod, nil}
        end

      IO.inspect(belt_module)

      prev_conveyor = request_acc.conveyor || new()

      new_request =
        belt_module
        |> apply(:call, [request_acc, prev_conveyor, belt_params])
        |> handle_result(request_acc)
        |> append_trace({belt_module, belt_params})

      # TODO: One could add a validation step here. For instance, `response_status`
      # should only be set if `halt?` is `true`

      if not new_request.conveyor.halt? do
        {:cont, new_request}
      else
        {:halt, new_request}
      end
    end)
  end

  def halt_with_response(request, conveyor, status, error_msg \\ "") when is_integer(status) do
    # TODO: Test this
    halted_conveyor =
      conveyor
      |> set_halt?()
      |> set_status(status)
      |> set_message(error_msg)

    %{request | conveyor: halted_conveyor}
  end

  def set_status(%__MODULE__{} = conveyor, status),
    do: Map.put(conveyor, :response_status, status)

  def set_message(%__MODULE__{} = conveyor, msg),
    do: Map.put(conveyor, :response_message, msg)

  def set_halt?(%__MODULE__{} = conveyor, halt? \\ true),
    do: Map.put(conveyor, :halt?, halt?)

  # TODO: Doc
  defp handle_result(%Conveyor{} = conveyor, prev_req),
    do: Map.put(prev_req, :conveyor, conveyor)

  defp handle_result(%{conveyor: %Conveyor{}} = req, _),
    do: req

  # TODO: Doc
  defp append_trace(
         %{conveyor: %Conveyor{}} = request,
         {belt_module, belt_params}
       ) do
    belt_entry =
      if is_nil(belt_params) do
        belt_module
      else
        {belt_module, belt_params}
      end

    update_in(
      request,
      [Access.key!(:conveyor), Access.key!(:trace)],
      fn trace -> trace ++ [belt_entry] end
    )
  end
end

defmodule Webserver.Conveyor.Belts.Entrypoint do
  def call(request, %Webserver.Conveyor{trace: []} = conveyor, _) do
    %{request | conveyor: conveyor}
  end
end
