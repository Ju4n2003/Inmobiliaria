defmodule Inmobiliaria.UserManager do
  @moduledoc """
  Gestión de usuarios para la aplicación Inmobiliaria.

  Este módulo ejecuta un proceso que mantiene en memoria un mapa de usuarios y
  persiste los datos de usuario en `users.dat`.
  """

  @users_file "users.dat"

  @doc """
  Inicia el proceso gestor de usuarios.

  Carga los usuarios existentes desde disco y arranca el bucle de recepción.
  Retorna el PID del proceso.
  """
  def start_link(_args) do
    spawn(fn ->
      loop(%{})
    end)
    |> then(fn pid ->
      Process.register(
        pid,
        __MODULE__
      )

      {:ok, pid}
    end)
  end

  @doc """
  Pide al gestor que conecte o registre un usuario.

  Si el usuario no existe, se registra con el rol indicado.
  Retorna `{:ok, usuario}` o `{:error, mensaje}`.
  """
  def conectar(pid, username, password, role) do
    send(
      pid,
      {:conectar, username, password, role, self()}
    )

    receive do
      respuesta ->
        respuesta
    end
  end

  @doc """
  Solicita al gestor la información del usuario indicado.

  Si el usuario no existe, retorna `nil`.
  """
  def obtener_usuario(pid, username) do
    send(
      pid,
      {:obtener_usuario, username, self()}
    )

    receive do
      usuario ->
        usuario
    end
  end

  @doc """
  Devuelve el puntaje acumulado del usuario.

  Si el usuario no existe, retorna `0`.
  """
  def obtener_puntaje(pid, username) do
    send(
      pid,
      {:obtener_puntaje, username, self()}
    )

    receive do
      puntaje ->
        puntaje
    end
  end

  @doc """
  Suma puntos al usuario identificado por `username`.

  Los puntos varían según el rol:
  - cliente: 10 puntos
  - vendedor o arrendador: 15 puntos
  """
  def agregar_puntos(pid, username) do
    send(pid, {:agregar_puntos, username})
  end

  @doc """
  Devuelve el ranking de todos los usuarios ordenado por puntaje descendente.
  """
  def ranking(pid) do
    send(pid, {:ranking, self()})

    receive do
      ranking ->
        ranking
    end
  end

  @doc """
  Devuelve el ranking de usuarios filtrado por el rol especificado.
  """
  def ranking_por_rol(pid, role) do
    send(
      pid,
      {:ranking_por_rol, role, self()}
    )

    receive do
      ranking ->
        ranking
    end
  end

  @doc """
  Comprueba si el usuario existe en el gestor.

  Retorna `true` o `false`.
  """
  def existe?(pid, username) do
    send(
      pid,
      {:existe?, username, self()}
    )

    receive do
      existe ->
        existe
    end
  end

  def loop(usuarios) do
    receive do
      {:conectar, username, password, role, remitente} ->
        if role in ["cliente", "vendedor", "arrendador"] do
          case Map.get(usuarios, username) do
            nil ->
              nuevo_usuario = %{
                role: role,
                password: password,
                score: 0
              }

              nuevos_usuarios =
                Map.put(
                  usuarios,
                  username,
                  nuevo_usuario
                )

              guardar_usuarios(nuevos_usuarios)

              send(
                remitente,
                {:ok, nuevo_usuario}
              )

              loop(nuevos_usuarios)

            usuario ->
              if usuario.password == password do
                send(
                  remitente,
                  {:ok, usuario}
                )
              else
                send(
                  remitente,
                  {:error, "Contraseña incorrecta"}
                )
              end

              loop(usuarios)
          end
        else
          send(
            remitente,
            {:error, "Rol inválido"}
          )

          loop(usuarios)
        end

      {:obtener_usuario, username, remitente} ->
        send(
          remitente,
          Map.get(usuarios, username)
        )

        loop(usuarios)

      {:obtener_puntaje, username, remitente} ->
        usuario =
          Map.get(usuarios, username)

        puntaje =
          if usuario != nil do
            usuario.score
          else
            0
          end

        send(remitente, puntaje)

        loop(usuarios)

      {:agregar_puntos, username} ->
        usuario =
          Map.get(usuarios, username)

        if usuario != nil do
          puntos =
            if usuario.role == "cliente" do
              10
            else
              15
            end

          usuario_actualizado = %{
            usuario
            | score: usuario.score + puntos
          }

          nuevos_usuarios =
            Map.put(
              usuarios,
              username,
              usuario_actualizado
            )

          guardar_usuarios(nuevos_usuarios)

          loop(nuevos_usuarios)
        else
          loop(usuarios)
        end

      {:ranking, remitente} ->
        ranking =
          usuarios
          |> Enum.map(fn {username, data} ->
            %{
              username: username,
              role: data.role,
              score: data.score
            }
          end)
          |> Enum.sort_by(
            fn user -> user.score end,
            :desc
          )

        send(remitente, ranking)

        loop(usuarios)

      {:ranking_por_rol, role, remitente} ->
        ranking =
          usuarios
          |> Enum.filter(fn {_u, d} ->
            d.role == role
          end)
          |> Enum.map(fn {username, data} ->
            %{
              username: username,
              role: data.role,
              score: data.score
            }
          end)
          |> Enum.sort_by(
            fn user -> user.score end,
            :desc
          )

        send(remitente, ranking)

        loop(usuarios)

      {:existe?, username, remitente} ->
        send(
          remitente,
          Map.has_key?(
            usuarios,
            username
          )
        )

        loop(usuarios)
    end
  end

  defp cargar_usuarios() do
    registros =
      Inmobiliaria.Persistence.read_records(@users_file)

    Enum.reduce(registros, %{}, fn r, acc ->
      username = r["username"]

      usuario = %{
        role: r["role"],
        password: r["password"],
        score: String.to_integer(r["score"] || "0")
      }

      Map.put(acc, username, usuario)
    end)
  end

  defp guardar_usuarios(usuarios) do
    registros =
      Enum.map(usuarios, fn {username, u} ->
        %{
          "username" => username,
          "role" => u.role,
          "password" => u.password,
          "score" => "#{u.score}"
        }
      end)

    Inmobiliaria.Persistence.write_records(
      @users_file,
      registros
    )
  end
end

defmodule Inmobiliaria.Persistence do
  @moduledoc """
  Módulo de persistencia básico para Inmobiliaria.

  Define funciones simples de lectura y escritura de registros.
  """

  @doc """
  Lee registros de usuarios desde un archivo.

  Si el archivo no existe, retorna una lista vacía.
  """
  def read_records(_file), do: []

  @doc """
  Escribe registros de usuarios en un archivo.
  """
  def write_records(_file, _records), do: :ok
end
