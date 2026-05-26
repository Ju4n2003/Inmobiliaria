defmodule Inmobiliaria.Server do
  @moduledoc """
  Módulo principal del servidor de la aplicación inmobiliaria.

  Este módulo administra la interacción del usuario mediante comandos
  ingresados desde la terminal. Actúa como intermediario entre el usuario
  y los diferentes gestores del sistema, tales como:

  - Gestión de usuarios
  - Gestión de propiedades
  - Gestión de mensajes
  - Registro de operaciones
  - Consulta de rankings

  El servidor mantiene un estado interno con el usuario autenticado
  actualmente y coordina las operaciones permitidas según el rol.
  """

  @doc """
  Inicia el servidor interactivo de la inmobiliaria.

  Obtiene los procesos registrados de los gestores principales
  (`UserManager` y `PropertyManager`), construye el estado inicial
  del sistema y comienza el ciclo principal de lectura de comandos.

  ## Retorna

  Un ciclo interactivo en terminal.

  ## Ejemplo

      iex> Inmobiliaria.Server.iniciar()

  """
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

  @doc """
  Ejecuta el ciclo principal del servidor.

  Este método permanece escuchando comandos desde la terminal
  y ejecuta acciones según el patrón ingresado por el usuario.

  El estado conserva:

  - `property_manager`: PID del gestor de propiedades
  - `user_manager`: PID del gestor de usuarios
  - `usuario_actual`: usuario autenticado

  ## Parámetros

  - `estado`: mapa con el estado actual del sistema.
  """
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
      #
      # Permite registrar o autenticar un usuario.
      # Si el usuario no existe se crea automáticamente.
      # El usuario conectado queda almacenado en el estado.
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
      #
      # Permite crear propiedades según el rol:
      #
      # - cliente -> no puede publicar
      # - vendedor -> solo venta
      # - arrendador -> solo arriendo
      #
      # Además valida:
      # - modalidad
      # - ubicación válida
      # - autenticación previa

      ["crear", tipo, modalidad, ubicacion, precio, habitaciones, area] ->
        if estado.usuario_actual != nil do
          usuario =
            Inmobiliaria.UserManager.obtener_usuario(
              estado.user_manager,
              estado.usuario_actual
            )

          ubicaciones =
            File.read!("data/locations.dat")
            |> String.split("\n")
            |> Enum.map(&String.trim/1)

          cond do
            modalidad not in ["venta", "arriendo"] ->
              IO.puts("Modalidad inválida. Use venta o arriendo")

            usuario.role == "cliente" ->
              IO.puts("Un cliente no puede publicar propiedades")

            usuario.role == "vendedor" and modalidad == "arriendo" ->
              IO.puts("Un vendedor solo puede publicar ventas")

            usuario.role == "arrendador" and modalidad == "venta" ->
              IO.puts("Un arrendador solo puede publicar arriendos")

            ubicacion not in ubicaciones ->
              IO.puts("Ubicación inválida")

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
      #
      # Muestra todas las propiedades registradas
      # junto con su información detallada.

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

        loop(estado)

      #
      # Filtra únicamente propiedades cuyo estado
      # sea "disponible".

      ["listar", "disponible"] ->
        propiedades =
          Inmobiliaria.PropertyManager.listar_propiedades(estado.property_manager)

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          if propiedad.estado == "disponible" do
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
          end
        end)

        loop(estado)

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

      #
      # Lista propiedades cuyo precio esté entre
      # un mínimo y máximo ingresado.
      #
      ["filtrar_precio", min, max] ->
        propiedades =
          Inmobiliaria.PropertyManager.listar_propiedades(estado.property_manager)

        Enum.each(propiedades, fn {id, pid_propiedad} ->
          propiedad =
            Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          precio = propiedad.precio

          if precio >= String.to_integer(min) and
               precio <= String.to_integer(max) do
            IO.puts("""

            -------------------------
            ID: #{id}
            Tipo: #{propiedad.tipo}
            Modalidad: #{propiedad.modalidad}
            Precio: #{propiedad.precio}
            Ubicación: #{propiedad.ubicacion}
            -------------------------

            """)
          end
        end)

        loop(estado)

      # ......................
      #    FILTRAR UBICACION
      # ......................

      # Solo los clientes pueden comprar propiedades.
      #
      # Cuando la compra es exitosa:
      # - se cambia el estado de la propiedad
      # - se registra la operación
      # - se otorgan puntos al comprador
      # - se otorgan puntos al vendedor

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
                  propiedad =
                    Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

                  Inmobiliaria.ResultManager.guardar_operacion(
                    estado.usuario_actual,
                    propiedad.propietario,
                    id_propiedad,
                    "compra",
                    propiedad.ubicacion,
                    propiedad.precio
                  )

                  IO.puts(mensaje)

                  # puntos al comprador
                  Inmobiliaria.UserManager.agregar_puntos(
                    estado.user_manager,
                    estado.usuario_actual
                  )

                  # puntos al vendedor/arrendador
                  Inmobiliaria.UserManager.agregar_puntos(
                    estado.user_manager,
                    propiedad.propietario
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
              case Inmobiliaria.Propiedad.comprar(
                     pid_propiedad,
                     estado.usuario_actual
                   ) do
                {:ok, mensaje} ->
                  propiedad =
                    Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

                  Inmobiliaria.ResultManager.guardar_operacion(
                    estado.usuario_actual,
                    propiedad.propietario,
                    id_propiedad,
                    "arriendo",
                    propiedad.ubicacion,
                    propiedad.precio
                  )

                  IO.puts(mensaje)

                  # puntos al arrendatario
                  Inmobiliaria.UserManager.agregar_puntos(
                    estado.user_manager,
                    estado.usuario_actual
                  )

                  # puntos al vendedor/arrendador
                  Inmobiliaria.UserManager.agregar_puntos(
                    estado.user_manager,
                    propiedad.propietario
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

          File.write!(
            "data/messages.log",
            "#{propiedad_id};#{estado.usuario_actual};#{mensaje}\n",
            [:append]
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

      ["ranking_rol", rol] ->
        ranking =
          Inmobiliaria.UserManager.ranking_por_rol(
            estado.user_manager,
            rol
          )

        Enum.each(ranking, fn usuario ->
          IO.puts("""
          Usuario: #{usuario.username}
          Rol: #{usuario.role}
          Puntos: #{usuario.score}
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

        ==========================================
               SISTEMA INMOBILIARIA - AYUDA
        ==========================================

        AUTENTICACIÓN
        ------------------------------------------
        connect usuario password rol
          Inicia sesión o registra un usuario.

          Roles disponibles:
            cliente
            vendedor
            arrendador

          Ejemplo:
            connect juan 123 cliente


        PROPIEDADES
        ------------------------------------------
        crear tipo modalidad ubicacion precio habitaciones area
          Publica una propiedad.

          Modalidades:
            venta
            arriendo

          Ejemplo:
            crear casa venta armenia 250000000 4 120
            crear apartamento arriendo bogota 1800000 2 80


        CONSULTAS
        ------------------------------------------
        listar
          Lista todas las propiedades

        listar disponibles
          Lista solo propiedades disponibles

        filtrar_tipo tipo
          Filtra propiedades por tipo

          Ejemplo:
            filtrar_tipo casa

        filtrar_ubicacion ciudad
          Filtra propiedades por ubicación

          Ejemplo:
            filtrar_ubicacion armenia

        filtrar_modalidad modalidad
          Filtra propiedades por modalidad

          Ejemplo:
            filtrar_modalidad venta

        filtrar_precio minimo maximo
          Filtra propiedades por rango de precio

          Ejemplo:
            filtrar_precio 100000000 300000000


        OPERACIONES
        ------------------------------------------
        comprar id_propiedad
          Compra una propiedad

          Ejemplo:
            comprar prop001

        arrendar id_propiedad
          Arrienda una propiedad

          Ejemplo:
            arrendar prop002


        MENSAJES
        ------------------------------------------
        mensaje id_propiedad texto
          Envía un mensaje sobre una propiedad

          Ejemplo:
            mensaje prop001 Hola estoy interesado

        ver_mensajes
          Muestra los mensajes almacenados


        RANKING
        ------------------------------------------
        ranking
          Muestra ranking general de usuarios

        ranking_rol rol
          Muestra ranking por rol

          Ejemplo:
            ranking_rol vendedor

        SESIÓN
        ------------------------------------------
        desconectar
          Cierra sesión actual

        salir
          Finaliza el servidor

        ==========================================

        """)

        loop(estado)

      # ......................
      #         ERROR
      # ......................

      _ ->
        IO.puts("Comando no válido")

        loop(estado)
    end
  end
end
