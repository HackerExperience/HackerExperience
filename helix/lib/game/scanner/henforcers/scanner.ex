defmodule Game.Henforcers.Scanner do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.{Entity, ScannerInstance}

  alias Game.Scanner.Params.Connection, as: ConnParams
  alias Game.Scanner.Params.File, as: FileParams
  alias Game.Scanner.Params.Log, as: LogParams

  @type instance_exists_relay :: %{instance: ScannerInstance.t()}
  @type instance_exists_error :: {false, {:instance, :not_found}, %{}}

  @doc """
  Checks whether th given ScannerInstance exists.
  """
  @spec instance_exists?(ScannerInstance.ID.t()) ::
          {true, instance_exists_relay}
          | instance_exists_error
  def instance_exists?(%ScannerInstance.ID{} = instance_id) do
    case Svc.Scanner.fetch_instance(by_id: instance_id) do
      %ScannerInstance{} = instance ->
        Henforcer.success(%{instance: instance})

      nil ->
        Henforcer.fail({:instance, :not_found})
    end
  end

  @type belongs_to_entity_relay :: %{instance: ScannerInstance.t(), entity: Entity.t()}
  @type belongs_to_entity_error :: {false, {:instance, :not_belongs}, %{}}

  @doc """
  Henforces that the given ScannerInstance belongs to the given Entity.
  """
  @spec belongs_to_entity?(ScannerInstance.t(), Entity.t()) ::
          {true, belongs_to_entity_relay}
          | belongs_to_entity_error
  def belongs_to_entity?(%ScannerInstance{} = instance, %Entity{} = entity) do
    if instance.entity_id == entity.id do
      Henforcer.success(%{instance: instance, entity: entity})
    else
      Henforcer.fail({:instance, :not_belongs})
    end
  end

  @type can_edit_relay :: %{instance: ScannerInstance.t(), entity: Entity.t()}
  @type can_edit_error ::
          instance_exists_error
          | belongs_to_entity_error

  @doc """
  Henforces that the given Entity can edit the given ScannerInstance.
  """
  @spec can_edit?(Entity.t(), ScannerInstance.ID.t()) ::
          {true, can_edit_relay}
          | can_edit_error
  def can_edit?(%Entity{} = entity, %ScannerInstance.ID{} = instance_id) do
    with {true, %{instance: instance}} <- instance_exists?(instance_id),
         {true, _} <- belongs_to_entity?(instance, entity) do
      Henforcer.success(%{instance: instance})
    end
  end

  def valid_params?(%ScannerInstance{type: :log}, %LogParams{}), do: Henforcer.success()
  def valid_params?(%ScannerInstance{type: :file}, %FileParams{}), do: Henforcer.success()
  def valid_params?(%ScannerInstance{type: :connection}, %ConnParams{}), do: Henforcer.success()
  def valid_params?(_, _), do: Henforcer.fail({:instance, :invalid_params})
end
