defmodule Inmobiliaria.Property do
  @moduledoc """
  Representa una propiedad como un proceso independiente.

  Cada propiedad vive como un GenServer y mantiene su
  propio estado privado.

  Permite:

  - consultar información
  - comprar propiedad
  - arrendar propiedad

  Gracias a GenServer, las operaciones se procesan
  secuencialmente evitando conflictos concurrentes.
  """

  use GenServer

  require Logger

  # ==================================================
  # API PÚBLICA
  # ==================================================

  @doc """
  Inicia el proceso de una propiedad.
  """
  def start_link(property_data) do
    id = property_data["id"]

    GenServer.start_link(
      __MODULE__,
      property_data,
      name: via_tuple(id)
    )
  end

  @doc """
  Retorna el estado completo de la propiedad.
  """
  def get_info(property_id) do
    case buscar_proceso(property_id) do
      nil ->
        {:error, "Propiedad no encontrada"}

      pid ->
        {:ok, GenServer.call(pid, :get_info)}
    end
  end

  @doc """
  Compra una propiedad.
  """
  def buy(property_id, buyer) do
    case buscar_proceso(property_id) do
      nil ->
        {:error, "Propiedad no encontrada"}

      pid ->
        GenServer.call(pid, {:buy, buyer})
    end
  end

  @doc """
  Arrienda una propiedad.
  """
  def rent(property_id, tenant) do
    case buscar_proceso(property_id) do
      nil ->
        {:error, "Propiedad no encontrada"}

      pid ->
        GenServer.call(pid, {:rent, tenant})
    end
  end

  # ==================================================
  # CALLBACKS DEL GENSERVER
  # ==================================================

  @impl true
  def init(property_data) do
    Logger.info(
      "Propiedad iniciada: #{property_data["id"]}"
    )

    {:ok, property_data}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:buy, buyer}, _from, state) do
    case validar_compra(state, buyer) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      :ok ->
        nuevo_estado =
          Map.put(
            state,
            "status",
            "vendida"
          )

        transaccion =
          crear_transaccion(
            state,
            buyer,
            "compra"
          )

        Logger.info(
          "Propiedad #{state["id"]} vendida"
        )

        {:reply,
         {:ok, transaccion},
         nuevo_estado}
    end
  end

  @impl true
  def handle_call({:rent, tenant}, _from, state) do
    case validar_arriendo(state, tenant) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      :ok ->
        nuevo_estado =
          Map.put(
            state,
            "status",
            "arrendada"
          )

        transaccion =
          crear_transaccion(
            state,
            tenant,
            "arriendo"
          )

        Logger.info(
          "Propiedad #{state["id"]} arrendada"
        )

        {:reply,
         {:ok, transaccion},
         nuevo_estado}
    end
  end

  # ==================================================
  # VALIDACIONES
  # ==================================================

  defp validar_compra(state, buyer) do
    cond do
      state["modality"] != "venta" ->
        {:error, "No está en venta"}

      state["status"] != "disponible" ->
        {:error, "Ya no está disponible"}

      state["owner"] == buyer ->
        {:error, "No puede comprar su propiedad"}

      true ->
        :ok
    end
  end

  defp validar_arriendo(state, tenant) do
    cond do
      state["modality"] != "arriendo" ->
        {:error, "No está en arriendo"}

      state["status"] != "disponible" ->
        {:error, "Ya no está disponible"}

      state["owner"] == tenant ->
        {:error, "No puede arrendar su propiedad"}

      true ->
        :ok
    end
  end

  # ==================================================
  # FUNCIONES AUXILIARES
  # ==================================================

  defp crear_transaccion(
         state,
         usuario,
         operacion
       ) do
    %{
      "client" => usuario,
      "responsible" => state["owner"],
      "property_id" => state["id"],
      "operation" => operacion,
      "location" => state["location"],
      "price" => state["price"],
      "final_status" => "Completada"
    }
  end

  defp buscar_proceso(property_id) do
    GenServer.whereis(
      via_tuple(property_id)
    )
  end

  defp via_tuple(property_id) do
    {:global, {:property, property_id}}
  end
end
