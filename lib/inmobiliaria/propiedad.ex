defmodule Inmobiliaria.Propiedad do
  use GenServer

  # ......................
  #       INICIO
  # ......................

  def start_link(datos_propiedad) do
    GenServer.start_link(__MODULE__, datos_propiedad)
  end

  def init(datos_propiedad) do
    {:ok, datos_propiedad}
  end

  # ......................
  #         API
  # ......................

  def obtener_estado(pid) do
    GenServer.call(pid, :obtener_estado)
  end

  def comprar(pid, cliente) do
    GenServer.call(pid, {:comprar, cliente})
  end

  def arrendar(pid, cliente) do
    GenServer.call(pid, {:arrendar, cliente})
  end

  # ......................
  #    CONSULTAR ESTADO
  # ......................

  def handle_call(:obtener_estado, _from, estado) do
    {:reply, estado, estado}
  end

  # ......................
  #        COMPRAR
  # ......................

  def handle_call({:comprar, cliente}, _from, propiedad) do
    cond do
      propiedad.modalidad != "venta" ->
        {:reply, {:error, "La propiedad no está en venta"}, propiedad}

      propiedad.estado != "disponible" ->
        {:reply, {:error, "La propiedad no está disponible"}, propiedad}

      true ->
        nuevo_estado = %{
          propiedad
          | estado: "vendida"
        }

        fecha =
          Date.utc_today()

        linea =
          "#{fecha};" <>
            "cliente=#{cliente};" <>
            "responsable=#{propiedad.propietario};" <>
            "propiedad=#{propiedad.id};" <>
            "operacion=compra;" <>
            "ubicacion=#{propiedad.ubicacion};" <>
            "precio=#{propiedad.precio};" <>
            "estado=vendida"

        Inmobiliaria.Persistence.guardar_linea(
          "data/results.log",
          linea
        )

        {:reply, {:ok, "#{cliente} compró la propiedad"}, nuevo_estado}
    end
  end

  # ......................
  #        ARRENDAR
  # ......................

  def handle_call({:arrendar, cliente}, _from, propiedad) do
    cond do
      propiedad.modalidad != "arriendo" ->
        {:reply, {:error, "La propiedad no está en arriendo"}, propiedad}

      propiedad.estado != "disponible" ->
        {:reply, {:error, "La propiedad no está disponible"}, propiedad}

      true ->
        nuevo_estado = %{
          propiedad
          | estado: "arrendada"
        }

        fecha =
          Date.utc_today()

        linea =
          "#{fecha};" <>
            "cliente=#{cliente};" <>
            "responsable=#{propiedad.propietario};" <>
            "propiedad=#{propiedad.id};" <>
            "operacion=arriendo;" <>
            "ubicacion=#{propiedad.ubicacion};" <>
            "precio=#{propiedad.precio};" <>
            "estado=arrendada"

        Inmobiliaria.Persistence.guardar_linea(
          "data/results.log",
          linea
        )

        {:reply, {:ok, "#{cliente} arrendó la propiedad"}, nuevo_estado}
    end
  end
end
