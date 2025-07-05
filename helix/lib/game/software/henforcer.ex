defmodule Game.Henforcers.Software do
  alias Core.Henforcer
  alias Game.{Software}

  @type type_exists_relay :: %{software: Software.t()}
  @type type_exists_error :: {false, {:software_type, :not_found}, %{}}

  @doc """
  Checks whether the given `software_type` is valid.
  """
  @spec type_exists?(Software.type()) ::
          {true, type_exists_relay}
          | type_exists_error
  def type_exists?(software_type) when is_atom(software_type) do
    case Software.get(software_type) do
      %Software{} = software ->
        Henforcer.success(%{software: software})

      nil ->
        Henforcer.fail({:software_type, :not_found})
    end
  end

  @type type_appstore_installable_relay :: %{software: Software.t()}
  @type type_appstore_installable_error :: {false, {:software_type, :not_appstore_installable}, %{}}

  @doc """
  Checks whether the given `software_type` can be installed in the AppStore.
  """
  @spec type_appstore_installable?(Software.type()) ::
          {true, type_appstore_installable_relay}
          | type_appstore_installable_error
  def type_appstore_installable?(software_type) when is_atom(software_type) do
    with {true, %{software: software}} <- type_exists?(software_type),
         true <- not is_nil(software.config.appstore) do
      Henforcer.success(%{software: software})
    else
      false ->
        Henforcer.fail({:software_type, :not_appstore_installable})

      {false, _, _} = henforcer_error ->
        henforcer_error
    end
  end
end
