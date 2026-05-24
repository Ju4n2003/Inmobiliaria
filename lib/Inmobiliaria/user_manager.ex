defmodule Inmobiliaria.UserManager do
  @archivo_usuarios "data/users.dat"

  def iniciar() do
    estado_inicial = %{
      usuarios: %{},
      conectados: %{}
    }

    spawn(fn -> loop(estado_inicial) end)
  end

  def conectar(pid_manager, username, password, rol) do
    send(pid_manager, {:conectar, username, password, rol, self()})

    receive do
      respuesta -> respuesta
    end
  end

  def sumar_puntos(pid_manager, username, puntos) do
    send(pid_manager, {:sumar_puntos, username, puntos})
  end

  def ranking(pid_manager) do
    send(pid_manager, {:ranking, self()})

    receive do
      ranking -> ranking
    end
  end

  def loop(estado) do
    receive do
      {:conectar, username, password, rol, remitente} ->
        usuarios_actualizados =
          if Map.has_key?(estado.usuarios, username) do
            usuario = Map.get(estado.usuarios, username)

            if usuario.password == password do
              send(remitente, "Login exitoso")
              estado.usuarios
            else
              send(remitente, "Contraseña incorrecta")
              estado.usuarios
            end
          else
            nuevo_usuario = %{
              username: username,
              password: password,
              rol: rol,
              puntos: 0
            }

            Inmobiliaria.Persistencia.guardar_usuario(nuevo_usuario)
            send(remitente, "Usuario registrado")
            Map.put(estado.usuarios, username, nuevo_usuario)
          end

        nuevos_conectados = Map.put(estado.conectados, username, true)

        nuevo_estado = %{
          usuarios: usuarios_actualizados,
          conectados: nuevos_conectados
        }

        loop(nuevo_estado)

      {:sumar_puntos, username, puntos} ->
        usuario = Map.get(estado.usuarios, username)

        if usuario != nil do
          usuario_actualizado = %{
            usuario
            | puntos: usuario.puntos + puntos
          }

          usuarios_actualizados = Map.put(estado.usuarios, username, usuario_actualizado)

          nuevo_estado = %{
            usuarios: usuarios_actualizados,
            conectados: estado.conectados
          }

          loop(nuevo_estado)
        else
          loop(estado)
        end

      {:ranking, remitente} ->
        ranking =
          estado.usuarios
          |> Map.values()
          |> Enum.sort_by(
            fn usuario -> usuario.puntos end,
            :desc
          )

        send(remitente, ranking)

        loop(estado)
    end
  end
end
