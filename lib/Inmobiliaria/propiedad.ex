defmodule Inmobiliaria.Propiedad do
  def iniciar(datos_propiedad) do
    spawn(fn -> loop(datos_propiedad) end)
  end

  def obtener_estado(pid) do

    #tupla para obtener el estado, con self() porque
    #el proceso necesita saber a quién enviar la respuesta,
    #entonces enviamos el emnsaje y quién lo pidió

    send(pid, {:obtener_estado, self()})

    #ESTE proceso queda esperando respuesta
    receive do
      #lo guarda el propiedad y retorna una propiedad
      propiedad -> propiedad
    end
  end

  def comprar(pid, cliente) do
    send(pid, {:comprar, cliente})
  end

  def loop(propiedad) do
    receive do
      #si llega una tupla así: {:obtener_estado, "algo"},
      #entonces, "algo" se guarda en remitente.
      {:obtener_estado, remitente} ->
        send(remitente, propiedad) #le responde al proceso que preguntó. Le manda el mapa completo

        loop(propiedad) #para que el proceso no muera, sino que siga esperando mensajes

      {:comprar, cliente} ->
        if propiedad.disponibilidad == "disponible" do
          nueva_propiedad = %{
            propiedad |
            disponibilidad: "vendida"
          }

          IO.puts("#{cliente} compró la propiedad")

          loop(nueva_propiedad) #el rpoceso continúa pero con el estado actualizado
        else
          IO.puts("La propiedad no está disponible")

          loop(propiedad)
        end
    end
  end
end
