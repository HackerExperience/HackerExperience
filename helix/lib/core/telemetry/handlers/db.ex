defmodule Core.Telemetry.Handlers.DB do
  def handle_event(event, measurements, metadata, config) do
    # This indirection is here to assist debugging when necessary
    do_handle_event(event, measurements, metadata, config)
  end

  def do_handle_event([:feebdb, :begin, :start], _, _, _) do
    Hotel.Tracer.start_span("DB:begin")
    :ok
  end

  def do_handle_event([:feebdb, :begin, :stop], %{duration: _duration}, _, _) do
    Hotel.Tracer.end_span()
  end

  def do_handle_event([:feebdb, :commit, :start], _, _, _) do
    Hotel.Tracer.start_span("DB:commit")
    :ok
  end

  def do_handle_event([:feebdb, :commit, :stop], %{duration: _duration}, _, _) do
    Hotel.Tracer.end_span()
  end

  def do_handle_event([:feebdb, :rollback, :start], _, _, _) do
    Hotel.Tracer.start_span("DB:rollback")
    :ok
  end

  def do_handle_event([:feebdb, :rollback, :stop], %{duration: _duration}, _, _) do
    Hotel.Tracer.end_span()
  end

  def do_handle_event([:feebdb, :query, :start], _, %{query_type: query_type}, _) do
    span_name =
      case query_type do
        :one -> "DB.one"
        :all -> "DB.all"
        :insert -> "DB.insert"
        :update -> "DB.update"
        :update_all -> "DB.update_all"
        :delete -> "DB.delete"
        :delete_all -> "DB.delete_all"
        :raw -> "DB.raw"
      end

    Hotel.Tracer.start_span(span_name)
    :ok
  end

  def do_handle_event([:feebdb, :query, :stop], %{duration: _duration}, _, _) do
    Hotel.Tracer.end_span()
  end
end
