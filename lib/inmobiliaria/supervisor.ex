defmodule Inmobiliaria.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def iniciar_propiedad(datos_propiedad) do
    spec = %{
      id: Inmobiliaria.Propiedad,
      start: {
        Inmobiliaria.Propiedad,
        :start_link,
        [datos_propiedad]
      }
    }

    DynamicSupervisor.start_child(
      __MODULE__,
      spec
    )
  end
end
