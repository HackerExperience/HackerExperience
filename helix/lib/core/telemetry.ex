defmodule Core.Telemetry do
  def setup do
    Hotel.Telemetry.setup_handlers()

    # TODO: Build event list dynamically (for DB and Webserver)

    :telemetry.attach_many(
      "feebdb_handlers",
      [
        [:feebdb, :begin, :start],
        [:feebdb, :begin, :stop],
        [:feebdb, :commit, :start],
        [:feebdb, :commit, :stop],
        [:feebdb, :rollback, :start],
        [:feebdb, :rollback, :stop],
        [:feebdb, :query, :start],
        [:feebdb, :query, :stop]
      ],
      &Core.Telemetry.Handlers.DB.handle_event/4,
      nil
    )

    :telemetry.attach_many(
      "webserver_request_start",
      [
        [:webserver, :request, :start],
        [:webserver, :request, :stop]
      ],
      &Core.Telemetry.Handlers.Webserver.handle_event/4,
      nil
    )
  end
end
