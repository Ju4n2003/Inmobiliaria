defmodule Inmobiliaria.Server do

  def iniciar() do
    
    pid_property_manager = Process.whereis(Inmobiliaria.PropertyManager)
    pid_user_manager = Process.whereis(Inmobiliaria.UserManager)

    estado = %{
      property_manager: pid_property_manager,
      user_manager: pid_user_manager,
      usuario_actual: nil
    }

    IO.puts("Servidor iniciado")
    loop(estado)
  end

  def loop(estado) do
    comando =
      IO.gets(">> ")
      |> String.trim()

    partes = String.split(comando, " ")

    case partes do
      ["connect", username, password, rol] ->
        respuesta = Inmobiliaria.UserManager.conectar(estado.user_manager, username, password, rol)

        IO.puts(respuesta)

        nuevo_estado = %{estado | usuario_actual: username}
        loop(nuevo_estado)

      ["crear"] ->
        if estado.usuario_actual != nil do
          propiedad = %{
            tipo: "casa",
            precio: 300_000_000,
            disponibilidad: "disponible",
            propietario: estado.usuario_actual
          }

          Inmobiliaria.PropertyManager.crear_propiedad(estado.property_manager, propiedad)
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      ["listar"] ->
        propiedades = Inmobiliaria.PropertyManager.listar_propiedades(estado.property_manager)

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad = Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          IO.puts("""
          -------------------------
          ID: #{id}
          Tipo: #{propiedad.tipo}
          Precio: #{propiedad.precio}
          Estado: #{propiedad.disponibilidad}
          Propietario: #{propiedad.propietario}
          -------------------------
          """)
        end)

        loop(estado)

      ["comprar", id_propiedad] ->
        if estado.usuario_actual != nil do
          pid_propiedad = Inmobiliaria.PropertyManager.obtener_propiedad(estado.property_manager, id_propiedad)

          if pid_propiedad != nil do
            Inmobiliaria.Propiedad.comprar(pid_propiedad, estado.usuario_actual)

            Inmobiliaria.UserManager.sumar_puntos(estado.user_manager, estado.usuario_actual, 10)
          else
            IO.puts("Propiedad no encontrada")
          end
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      ["mensaje", propiedad_id | resto_mensaje] ->
        if estado.usuario_actual != nil do
          mensaje =
            Enum.join(
              resto_mensaje,
              " "
            )

          Inmobiliaria.MessageManager.enviar_mensaje(propiedad_id,estado.usuario_actual,mensaje)
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      ["ver_mensajes"] ->
        mensajes = Inmobiliaria.MessageManager.ver_mensajes()

        Enum.each(mensajes, fn mensaje ->
          IO.puts("""
          #{mensaje}
          -------------------------
          """)
        end)

        loop(estado)

      ["ranking"] ->
        ranking = Inmobiliaria.UserManager.ranking(estado.user_manager)

        Enum.each(ranking, fn usuario ->
          IO.puts("""
          Usuario: #{usuario.username}
          Rol: #{usuario.rol}
          Puntos: #{usuario.puntos}
          -------------------------
          """)
        end)

        loop(estado)

      ["salir"] ->
        IO.puts("Servidor finalizado")

      _ ->
        IO.puts("Comando no válido")
        loop(estado)
    end
  end
end
