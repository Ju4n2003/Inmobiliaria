defmodule Inmobiliaria.Server do
@moduledoc """
será el módulo principal del sistema
este será la consola, el punto central y el lugar donde llegan los comandos
"""

@doc """
Función para arrancar el sistema
"""
  def iniciar() do

    #Aquí incia el PopertyManager
    #crea el proceso administrador de propiedades
    #devuelve el pid del manager ejemplo: #PID<0.145.0>
    pid_manager = Inmobiliaria.PropertyManager.iniciar()
    IO.puts("Servidor iniciado")
    loop(pid_manager) #comienza el ciclo infinito del servidor
    #se le pasa el pid del manager, porque el server necesitará usarlo todo el tiempo

  end

  @doc """
  Función que representa la vida completa del servidor, aquí se reciben los comandos y se ejecutan las acciones correspondientes
   - crear: crea una propiedad con datos predefinidos
   - listar: muestra todas las propiedades registradas
   - comprar: compra la propiedad prop001 por el cliente "ana"
   - estado: muestra el estado actual de la propiedad prop001
   - salir: finaliza el servidor
  """

  def loop(pid_manager) do
    comando = IO.gets(">> ") #espera la entrada del usuario
    # el IO.gets retorna: un string con salto de línea incluido
    case String.trim(comando) do

      "crear" ->

        propiedad =
        %{tipo: "casa",
        precio: 300000000,
        disponibilidad: "disponible"}

        Inmobiliaria.PropertyManager.crear_propiedad(pid_manager,propiedad)

        loop(pid_manager)

      "listar" ->

        propiedades = Inmobiliaria.PropertyManager.listar_propiedades(pid_manager)
        
        Enum.each(propiedades, fn {id, pid_propiedad} ->
          estado = Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)

          IO.puts("""
          ID: #{id}
          Tipo: #{estado.tipo}
          Precio: #{estado.precio}
          Estado: #{estado.disponibilidad}
          """)
        end)

        loop(pid_manager)

      "comprar" ->

        id_propiedad =
          IO.gets("ID propiedad: ")
          |> String.trim()

        pid_propiedad = Inmobiliaria.PropertyManager.obtener_propiedad(pid_manager,id_propiedad)

        if pid_propiedad != nil do

          Inmobiliaria.Propiedad.comprar(pid_propiedad,"ana")

        else
          IO.puts("Propiedad no encontrada")
        end

        loop(pid_manager)

      "estado" ->

        id_propiedad = IO.gets("ID propiedad: ")
          |> String.trim()

        pid_propiedad = Inmobiliaria.PropertyManager.obtener_propiedad(pid_manager,id_propiedad)

        if pid_propiedad != nil do

          estado = Inmobiliaria.Propiedad.obtener_estado(pid_propiedad)
          IO.inspect(estado)

        else
          IO.puts("Propiedad no encontrada")
        end

        loop(pid_manager)

      "salir" -> #finaliza servidor
        IO.puts("Servidor finalizado")

      _ -> #este es el último caso, significa cualquir otra cosa
      #cualquier otra cosa que no sea ninguna de las anteriores


        IO.puts("Comando no válido")
        loop(pid_manager) #si el comando no existe, el servidor sigue funcionando

    end
  end
end
