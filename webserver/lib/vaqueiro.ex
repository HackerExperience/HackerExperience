defmodule Webserver.Vaqueiro do
  @moduledoc """
  NOTE: This could also be moved to its own library, just like Conveyor.
  Middleman between Helix and `:cowboy_req`. Heavily based on Plug.Cowboy.Conn.
  """

  # NOTE: I don't know if this handles multipart uploads. Needs confirmation.
  def read_req_body(req, opts \\ []) do
    length = Keyword.get(opts, :length, 8_000_000)
    read_length = Keyword.get(opts, :read_length, 1_000_000)
    read_timeout = Keyword.get(opts, :read_timeout, 15_000)

    opts = %{length: read_length, period: read_timeout}
    read_req_body(req, opts, length, [])
  end

  defp read_req_body(req, opts, length, acc) when length >= 0 do
    case :cowboy_req.read_body(req, opts) do
      {:ok, data, req} ->
        {:ok, IO.iodata_to_binary([acc | data]), req}

      {:more, data, req} ->
        read_req_body(req, opts, length - byte_size(data), [acc | data])
    end
  end

  defp read_req_body(req, _opts, _length, acc) do
    {:more, IO.iodata_to_binary(acc), req}
  end
end
