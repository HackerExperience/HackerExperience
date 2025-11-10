defmodule Game.Scanner.Params.Log do
  require Logger

  defstruct [:date_from, :date_to, :direction, :type]

  def cast(raw_params) do
    with {:ok, {type, direction}} <- cast_type_and_direction(raw_params),
         {:ok, {date_to, date_from}} <- cast_date_range(raw_params) do
      params =
        %__MODULE__{
          date_from: date_from,
          date_to: date_to,
          direction: direction,
          type: type
        }

      {:ok, params}
    end
  end

  def on_db_load(%__MODULE__{} = params) do
    %__MODULE__{
      date_from: params.date_from,
      date_to: params.date_to,
      direction: params.direction && String.to_existing_atom(params.direction),
      type: params.type && String.to_existing_atom(params.type)
    }
  end

  defp cast_type_and_direction(%{"type" => raw_type, "direction" => raw_direction} = raw_params) do
    direction =
      if raw_direction in ["self", "to_ap", "from_en", "hop"] do
        String.to_existing_atom(raw_direction)
      else
        nil
      end

    valid? =
      case {raw_type, direction} do
        {_, nil} -> false
        {nil, _} -> false
        {"custom", :self} -> true
        {"file_deleted", dir} when dir in [:self, :to_ap, :from_en] -> true
        {"file_downloaded", dir} when dir in [:to_ap, :from_en] -> true
        {"file_uploaded", dir} when dir in [:to_ap, :from_en] -> true
        {"server_login", dir} when dir in [:self, :to_ap, :from_en] -> true
        {"connection_proxied", :hop} -> true
        _ -> false
      end

    if valid? do
      {:ok, {String.to_existing_atom(raw_type), direction}}
    else
      Logger.warning("Invalid log type/direction: #{inspect(raw_params)}")
      :error
    end
  end

  defp cast_type_and_direction(%{}), do: {:ok, {nil, nil}}

  # TODO
  defp cast_date_range(_), do: {:ok, {nil, nil}}

  def empty?(%__MODULE__{} = params) do
    params
    |> Map.from_struct()
    |> Map.values()
    |> Enum.all?(&is_nil/1)
  end
end
