defmodule Inmobiliaria.PropertySupervisor do
  @moduledoc """
  Se encarga de administrar las propiedades activas.
  """

  def iniciar() do
    spawn(fn -> loop(%{}) end)
  end

  def agregar_propiedad(pid_supervisor, id, datos_propiedad) do
    send(
      pid_supervisor,
      {:agregar_propiedad, id, datos_propiedad}
    )
  end

  def obtener_propiedad(pid_supervisor, id) do
    send(
      pid_supervisor,
      {:obtener_propiedad, id, self()}
    )

    receive do
      pid_propiedad ->
        pid_propiedad
    end
  end

  def listar_propiedades(pid_supervisor) do
    send(
      pid_supervisor,
      {:listar_propiedades, self()}
    )

    receive do
      propiedades ->
        propiedades
    end
  end

  def cantidad_propiedades(pid_supervisor) do
    send(
      pid_supervisor,
      {:cantidad_propiedades, self()}
    )

    receive do
      cantidad ->
        cantidad
    end
  end

  def loop(propiedades) do
    receive do

      {:agregar_propiedad, id, datos_propiedad} ->

        pid_propiedad =
          Inmobiliaria.Propiedad.iniciar(
            datos_propiedad
          )

        nuevas_propiedades =
          Map.put(
            propiedades,
            id,
            pid_propiedad
          )

        IO.puts(
          "Propiedad #{id} agregada"
        )

        loop(nuevas_propiedades)

      {:obtener_propiedad, id, remitente} ->

        pid_propiedad =
          Map.get(propiedades, id)

        send(remitente, pid_propiedad)

        loop(propiedades)

      {:listar_propiedades, remitente} ->

        send(
          remitente,
          Map.to_list(propiedades)
        )

        loop(propiedades)

      {:cantidad_propiedades, remitente} ->

        send(
          remitente,
          map_size(propiedades)
        )

        loop(propiedades)
    end
  end
end
