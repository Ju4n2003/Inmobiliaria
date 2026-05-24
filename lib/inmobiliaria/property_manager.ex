defmodule Inmobiliaria.PropertyManager do
  @moduledoc """
  Módulo administrador: guardar propiedades, buscar propiedades, listar propiedades
  """

  use GenServer

  def start_link(_args) do
    GenServer.start_link(
      __MODULE__,
      %{
        propiedades: %{},
        contador: 1
      },
      name: __MODULE__
    )
  end

  def init(estado) do
    {:ok, estado}
  end

  def crear_propiedad(pid_manager, datos_propiedad) do
    GenServer.cast(pid_manager, {:crear_propiedad, datos_propiedad})
  end

  def obtener_propiedad(pid_manager, id_propiedad) do
    GenServer.call(pid_manager, {:obtener_propiedad, id_propiedad})
  end

  def listar_propiedades(pid_manager) do
    GenServer.call(pid_manager, :listar_propiedades)
  end

  def filtrar_tipo(pid_manager, tipo) do
    GenServer.call(
      pid_manager,
      {:filtrar_tipo, tipo}
    )
  end

  def filtrar_ubicacion(pid_manager, ubicacion) do
    GenServer.call(
      pid_manager,
      {:filtrar_ubicacion, ubicacion}
    )
  end

  def filtrar_modalidad(pid_manager, modalidad) do
    GenServer.call(
      pid_manager,
      {:filtrar_modalidad, modalidad}
    )
  end

  def handle_cast({:crear_propiedad, datos_propiedad}, estado) do
    id_propiedad = "prop00#{estado.contador}"

    propiedad_completa =
      Map.put(datos_propiedad, :id, id_propiedad)

    resultado =
      Inmobiliaria.Supervisor.iniciar_propiedad(propiedad_completa)

    case resultado do
      {:ok, pid_propiedad} ->
        Inmobiliaria.Persistence.guardar_linea(
          "data/properties.dat",
          "#{id_propiedad};#{propiedad_completa.tipo};#{propiedad_completa.modalidad};#{propiedad_completa.ubicacion};#{propiedad_completa.precio};#{propiedad_completa.habitaciones};#{propiedad_completa.area};#{propiedad_completa.estado};#{propiedad_completa.propietario}"
        )

        nuevas_propiedades =
          Map.put(
            estado.propiedades,
            id_propiedad,
            pid_propiedad
          )

        nuevo_estado = %{
          propiedades: nuevas_propiedades,
          contador: estado.contador + 1
        }

        IO.puts("Propiedad #{id_propiedad} registrada")

        {:noreply, nuevo_estado}

      {:error, razon} ->
        IO.puts("Error al crear propiedad")

        IO.inspect(razon)

        {:noreply, estado}
    end
  end

  def handle_call({:obtener_propiedad, id_propiedad}, _from, estado) do
    pid_propiedad = Map.get(estado.propiedades, id_propiedad)

    {:reply, pid_propiedad, estado}
  end

  def handle_call(:listar_propiedades, _from, estado) do
    {:reply, estado.propiedades, estado}
  end

  def handle_call({:filtrar_tipo, tipo}, _from, estado) do
    filtradas =
      Enum.filter(
        estado.propiedades,
        fn {_id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          propiedad.tipo == tipo
        end
      )

    {:reply, filtradas, estado}
  end

  def handle_call({:filtrar_ubicacion, ubicacion}, _from, estado) do
    filtradas =
      Enum.filter(
        estado.propiedades,
        fn {_id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          propiedad.ubicacion == ubicacion
        end
      )

    {:reply, filtradas, estado}
  end

  def handle_call({:filtrar_modalidad, modalidad}, _from, estado) do
    filtradas =
      Enum.filter(
        estado.propiedades,
        fn {_id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          propiedad.modalidad == modalidad
        end
      )

    {:reply, filtradas, estado}
  end
end
