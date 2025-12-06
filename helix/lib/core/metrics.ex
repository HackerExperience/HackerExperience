defmodule Core.Metrics do
  def setup do
    Hotel.Telemetry.setup_metrics()
    Core.Metrics.DB.setup()
    Core.Metrics.Webserver.setup()
  end
end
