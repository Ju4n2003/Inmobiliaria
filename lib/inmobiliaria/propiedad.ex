defmodule Inmobiliaria.Propiedad do
  use GenServer

  def start_link(datos_propiedad) do
    GenServer.start_link(
      __MODULE__,
      datos_propiedad
    )
  end

  def init(datos_propiedad) do
    {:ok, datos_propiedad}
  end

  def obtener_estado(pid) do
    GenServer.call(pid, :obtener_estado)
  end

  def comprar(pid, cliente) do
    GenServer.cast(pid, {:comprar, cliente})
  end

  def handle_call(:obtener_estado, _from, estado) do
    {:reply, estado, estado}
  end

  def handle_cast({:comprar, cliente}, propiedad) do
    if propiedad.disponibilidad == "disponible" do
      nuevo_estado = %{
        propiedad
        | disponibilidad: "vendida"
      }

      Inmobiliaria.Persistencia.guardar_resultado(
        cliente,
        nuevo_estado,
        "compra"
      )

      IO.puts("#{cliente} compró la propiedad")

      {:noreply, nuevo_estado}
    else
      IO.puts("La propiedad no está disponible")

      {:noreply, propiedad}
    end
  end
end
