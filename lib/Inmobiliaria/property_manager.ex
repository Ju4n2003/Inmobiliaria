defmodule Inmobiliaria.PropertyManager do

  def iniciar() do
    spawn(fn -> loop(%{}) end)
  end

  def crear_propiedad(pid_manager, datos_propiedad) do
    send(pid_manager, {:crear_propiedad, datos_propiedad})
  end

  def obtener_propiedad(pid_manager, id_propiedad) do
    send(pid_manager, {:obtener_propiedad, id_propiedad, self()})

    receive do
      pid_propiedad -> pid_propiedad
    end
  end

  def listar_propiedades(pid_manager) do
    send(pid_manager, {:listar_propiedades, self()})

    receive do
      propiedades -> propiedades
    end
  end

  def loop(propiedades) do
    receive do
      {:crear_propiedad, datos_propiedad} ->

        pid_propiedad = Inmobiliaria.Propiedad.iniciar(datos_propiedad)
        nuevas_propiedades =

          Map.put(
            propiedades,
            datos_propiedad.id,
            pid_propiedad
          )

        IO.puts("Propiedad registrada")
        loop(nuevas_propiedades)

      {:obtener_propiedad, id_propiedad, remitente} ->
        pid_propiedad = Map.get(propiedades, id_propiedad)
        send(remitente, pid_propiedad)
        loop(propiedades)

      {:listar_propiedades, remitente} ->
        send(remitente, propiedades)
        loop(propiedades)
    end
  end
end
