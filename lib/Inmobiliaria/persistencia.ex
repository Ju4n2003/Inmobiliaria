defmodule Inmobiliaria.Persistencia do
  
  @archivo_propiedades "data/properties.dat"

  def guardar_propiedad(propiedad) do

    linea =
      "#{propiedad.id};" <>
        "#{propiedad.tipo};" <>
        "#{propiedad.precio};" <>
        "#{propiedad.disponibilidad}\n"

    File.write!(@archivo_propiedades, linea, [:append])
  end

  def leer_propiedades() do

    if File.exists?(@archivo_propiedades) do

      contenido = File.read!(@archivo_propiedades)
      String.split(contenido, "\n", trim: true)

    else
      []
    end
  end

  def guardar_resultado(
        cliente,
        propiedad,
        operacion
      ) do
    fecha = Date.utc_today()

    linea =
      "#{fecha};" <>
        "cliente=#{cliente};" <>
        "propiedad=#{propiedad.id};" <>
        "operacion=#{operacion};" <>
        "tipo=#{propiedad.tipo};" <>
        "precio=#{propiedad.precio};" <>
        "estado=#{propiedad.disponibilidad}\n"

    File.write!("data/results.log", linea, [:append])
  end
end
