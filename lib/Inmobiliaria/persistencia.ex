defmodule Inmobiliaria.Persistencia do

  @archivo_propiedades "data/properties.dat"

  def guardar_propiedad(propiedad) do

    linea =
      "#{propiedad.id};" <>
      "#{propiedad.tipo};" <>
      "#{propiedad.precio};" <>
      "#{propiedad.disponibilidad}\n"

    File.write!(@archivo_propiedades,linea,[:append])
  end

  def leer_propiedades() do

    if File.exists?(@archivo_propiedades) do

      contenido = File.read!(@archivo_propiedades)
      String.split(contenido, "\n", trim: true)

    else
      []
    end
  end
end
