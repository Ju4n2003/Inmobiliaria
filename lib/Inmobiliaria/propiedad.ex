defmodule Inmobiliaria.Propiedad do
  def iniciar(datos_propiedad) do
    spawn(fn -> loop(datos_propiedad) end)
  end

  def obtener_estado(pid) do
    send(pid, {:obtener_estado, self()})

    receive do
      estado -> estado
    end
  end

  def comprar(pid, cliente) do
    send(pid, {:comprar, cliente})
  end

  def loop(propiedad) do
    receive do
      {:obtener_estado, remitente} ->
        send(remitente, propiedad)

        loop(propiedad)

      {:comprar, cliente} ->
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

          loop(nuevo_estado)
        else
          IO.puts("La propiedad no está disponible")

          loop(propiedad)
        end
    end
  end
end
