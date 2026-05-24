defmodule Inmobiliaria.Server do
  def iniciar() do
    pid_property_manager =
      Process.whereis(Inmobiliaria.PropertyManager)

    pid_user_manager =
      Process.whereis(Inmobiliaria.UserManager)

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

    partes =
      String.split(comando, " ")

    case partes do
      # ......................
      #       CONNECT
      # ......................

      ["connect", username, password, rol] ->
        respuesta =
          Inmobiliaria.UserManager.conectar(
            estado.user_manager,
            username,
            password,
            rol
          )

        IO.inspect(respuesta)

        nuevo_estado = %{
          estado
          | usuario_actual: username
        }

        loop(nuevo_estado)

      # ......................
      #       CREAR PROPIEDAD
      # ......................

      ["crear", tipo, modalidad, ubicacion, precio, habitaciones, area] ->
        if estado.usuario_actual != nil do
          usuario =
            Inmobiliaria.UserManager.obtener_usuario(
              estado.user_manager,
              estado.usuario_actual
            )

          cond do
            modalidad not in ["venta", "arriendo"] ->
              IO.puts("Modalidad inválida. Use venta o arriendo")

            usuario.role == "cliente" ->
              IO.puts("Un cliente no puede publicar propiedades")

            usuario.role == "vendedor" and modalidad == "arriendo" ->
              IO.puts("Un vendedor solo puede publicar ventas")

            usuario.role == "arrendador" and modalidad == "venta" ->
              IO.puts("Un arrendador solo puede publicar arriendos")

            true ->
              propiedad = %{
                tipo: tipo,
                modalidad: modalidad,
                ubicacion: ubicacion,
                precio: String.to_integer(precio),
                habitaciones: String.to_integer(habitaciones),
                area: String.to_integer(area),
                estado: "disponible",
                propietario: estado.usuario_actual
              }

              Inmobiliaria.PropertyManager.crear_propiedad(
                estado.property_manager,
                propiedad
              )
          end
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      # ......................
      #       LISTAR
      # ......................

      ["listar"] ->
        propiedades =
          Inmobiliaria.PropertyManager.listar_propiedades(estado.property_manager)

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          IO.puts("""

          -------------------------
          ID: #{id}
          Tipo: #{propiedad.tipo}
          Modalidad: #{propiedad.modalidad}
          Ubicación: #{propiedad.ubicacion}
          Precio: #{propiedad.precio}
          Habitaciones: #{propiedad.habitaciones}
          Área: #{propiedad.area}
          Estado: #{propiedad.estado}
          Propietario: #{propiedad.propietario}
          -------------------------

          """)
        end)

      # ......................
      #       FILTRAR TIPO
      # ......................

      ["filtrar_tipo", tipo] ->
        propiedades =
          Inmobiliaria.PropertyManager.filtrar_tipo(
            estado.property_manager,
            tipo
          )

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          IO.puts("""

          -------------------------
          ID: #{id}
          Tipo: #{propiedad.tipo}
          Modalidad: #{propiedad.modalidad}
          Ubicación: #{propiedad.ubicacion}
          Precio: #{propiedad.precio}
          -------------------------

          """)
        end)

        loop(estado)

      # ......................
      #    FILTRAR UBICACION
      # ......................

      ["filtrar_ubicacion", ubicacion] ->
        propiedades =
          Inmobiliaria.PropertyManager.filtrar_ubicacion(
            estado.property_manager,
            ubicacion
          )

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          IO.puts("""

          -------------------------
          ID: #{id}
          Tipo: #{propiedad.tipo}
          Ubicación: #{propiedad.ubicacion}
          Precio: #{propiedad.precio}
          -------------------------

          """)
        end)

        loop(estado)

      # ......................
      #   FILTRAR MODALIDAD
      # ......................

      ["filtrar_modalidad", modalidad] ->
        propiedades =
          Inmobiliaria.PropertyManager.filtrar_modalidad(
            estado.property_manager,
            modalidad
          )

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          IO.puts("""

          -------------------------
          ID: #{id}
          Tipo: #{propiedad.tipo}
          Modalidad: #{propiedad.modalidad}
          Precio: #{propiedad.precio}
          -------------------------

          """)
        end)

        loop(estado)

      # ......................
      #       COMPRAR
      # ......................

      ["comprar", id_propiedad] ->
        if estado.usuario_actual != nil do
          usuario =
            Inmobiliaria.UserManager.obtener_usuario(
              estado.user_manager,
              estado.usuario_actual
            )

          if usuario.role == "cliente" do
            pid_propiedad =
              Inmobiliaria.PropertyManager.obtener_propiedad(
                estado.property_manager,
                id_propiedad
              )

            if pid_propiedad != nil do
              case Inmobiliaria.Propiedad.comprar(
                     pid_propiedad,
                     estado.usuario_actual
                   ) do
                {:ok, mensaje} ->
                  IO.puts(mensaje)

                  Inmobiliaria.UserManager.agregar_puntos(
                    estado.user_manager,
                    estado.usuario_actual
                  )

                {:error, error} ->
                  IO.puts(error)
              end
            else
              IO.puts("Propiedad no encontrada")
            end
          else
            IO.puts("Solo clientes pueden comprar")
          end
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      # .......................
      #       ARRENDAR
      # .......................

      ["arrendar", id_propiedad] ->
        if estado.usuario_actual != nil do
          usuario =
            Inmobiliaria.UserManager.obtener_usuario(
              estado.user_manager,
              estado.usuario_actual
            )

          if usuario.role == "cliente" do
            pid_propiedad =
              Inmobiliaria.PropertyManager.obtener_propiedad(
                estado.property_manager,
                id_propiedad
              )

            if pid_propiedad != nil do
              case Inmobiliaria.Propiedad.arrendar(
                     pid_propiedad,
                     estado.usuario_actual
                   ) do
                {:ok, mensaje} ->
                  IO.puts(mensaje)

                  Inmobiliaria.UserManager.agregar_puntos(
                    estado.user_manager,
                    estado.usuario_actual
                  )

                {:error, error} ->
                  IO.puts(error)
              end
            else
              IO.puts("Propiedad no encontrada")
            end
          else
            IO.puts("Solo clientes pueden arrendar")
          end
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      # ......................
      #       MENSAJES
      # .......................

      ["mensaje", propiedad_id | resto_mensaje] ->
        if estado.usuario_actual != nil do
          mensaje =
            Enum.join(
              resto_mensaje,
              " "
            )

          Inmobiliaria.MessageManager.enviar_mensaje(
            propiedad_id,
            estado.usuario_actual,
            mensaje
          )
        else
          IO.puts("Debe iniciar sesión")
        end

        loop(estado)

      # ......................
      #       VER MENSAJES
      # ......................

      ["ver_mensajes"] ->
        mensajes =
          Inmobiliaria.MessageManager.ver_mensajes()

        Enum.each(mensajes, fn mensaje ->
          IO.puts("""

          #{mensaje}
          -------------------------

          """)
        end)

        loop(estado)

      # ......................
      #       RANKING
      # ......................

      ["ranking"] ->
        ranking =
          Inmobiliaria.UserManager.ranking(estado.user_manager)

        Enum.each(ranking, fn usuario ->
          IO.puts("""

          Usuario: #{usuario.username}
          Rol: #{usuario.role}
          Puntos: #{usuario.score}
          -------------------------

          """)
        end)

        loop(estado)

      # ......................
      #       DESCONECTAR
      # ......................

      ["desconectar"] ->
        IO.puts("Sesión cerrada")

        nuevo_estado = %{
          estado
          | usuario_actual: nil
        }

        loop(nuevo_estado)

      # ......................
      #         AYUDA
      # ......................

      ["ayuda"] ->
        IO.puts("""

        COMANDOS DISPONIBLES

        connect usuario password rol

        crear tipo modalidad ubicacion precio habitaciones area

        listar

        comprar id_propiedad

        arrendar id_propiedad

        mensaje id_propiedad texto

        ver_mensajes

        ranking

        filtrar_tipo casa

        filtrar_ubicacion armenia

        filtrar_modalidad venta

        desconectar

        salir

        """)

        loop(estado)

      # ......................
      #         SALIR
      # ......................

      ["salir"] ->
        IO.puts("Servidor finalizado")

      # ......................
      #         ERROR
      # ......................

      _ ->
        IO.puts("Comando no válido")

        loop(estado)
    end
  end
end
