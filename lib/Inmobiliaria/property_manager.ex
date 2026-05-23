@moduledoc """
Módulo administrador: guardar propiedades, buscar propiedades, listar propiedades
"""
defmodule Inmobiliaria.PropertyManager do

  #función para iniciarel Manager
  def iniciar() do

    estado_inicial =
      %{propiedades: %{},
      contador: 1}

    #Crea proceso concuerrente nuevo
    spawn(fn -> loop(estado_inicial) end)
    #el nuevo proceso ejecutará loop(estado_inicial) que es un mapa vacío
    #el mapa vacío guardará las propiedades registradas
    # %{"prop001" => #PID<0.145.0>,"prop002" => #PID<0.146.0>}
    #el mapa es el estado interno del manager
  end

  #Función pública para crear propiedades así:
  #%{id: "prop001",tipo: "casa",precio: 300000000,disponibilidad: "disponible"}


  def crear_propiedad(pid_manager, datos_propiedad) do
    #send: envía un mensaje al manager:
    #tipo: manager crea esta propiedad

    send(pid_manager, {:crear_propiedad, datos_propiedad})
  end

  #Función pública para buscar propiedades
  def obtener_propiedad(pid_manager, id_propiedad) do
    #send: manda mensaje tipo: dame la rpopiedad prop001 y responde a este proceso
    send(pid_manager, {:obtener_propiedad, id_propiedad, self()})
    #self: significa el proceso actuál "yo"
    receive do #ahora esperamos respuesta
      pid_propiedad -> pid_propiedad #cuando llega el pid lo duardamos y retornamos
      #aquí no recibimos el mapa como tal, recibimos el pid del proceso que nos indica que está "vivo"
      #porque la propiedad vive en otro proceso y necesitamos hablar con ese proceso
    end
  end

  #función pública para listar TODAS las propiedades
  def listar_propiedades(pid_manager) do
    #lsend: le dice al manager que le mande todas las propiedades
    send(pid_manager, {:listar_propiedades, self()})

    #esperamos el mapa completo
    #ejemplo: %{"prop001" => #PID<0.145.0>,"prop002" => #PID<0.146.0>

    receive do
      propiedades -> propiedades
    end
  end

  #este es el corazón, aquí vive el estado manager, contiene el mapa global de propiedades
  def loop(estado) do

    receive do

      {:crear_propiedad, datos_propiedad} ->

        id_propiedad = "prop00#{estado.contador}"
        datos_completos = Map.put(datos_propiedad,:id,id_propiedad)
        pid_propiedad = Inmobiliaria.Propiedad.iniciar(datos_completos)
        nuevas_propiedades = Map.put(estado.propiedades,id_propiedad,pid_propiedad)
        nuevo_estado = %{propiedades: nuevas_propiedades,contador: estado.contador + 1}

        IO.puts("Propiedad #{id_propiedad} registrada")
        loop(nuevo_estado)

      {:obtener_propiedad, id_propiedad, remitente} ->

        pid_propiedad = Map.get(estado.propiedades,id_propiedad)
        send(remitente, pid_propiedad)
        loop(estado)

      {:listar_propiedades, remitente} ->

        send(remitente,estado.propiedades)
        loop(estado)

    end
  end
end
