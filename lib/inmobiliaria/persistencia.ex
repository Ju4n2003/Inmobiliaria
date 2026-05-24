defmodule Inmobiliaria.Persistence do
  @moduledoc """
  Persistencia simple usando archivos de texto plano.
  """

  def guardar_linea(archivo, linea) do
    File.write!(
      archivo,
      linea <> "\n",
      [:append]
    )
  end

  def leer_lineas(archivo) do
    if File.exists?(archivo) do
      archivo
      |> File.read!()
      |> String.split("\n", trim: true)
    else
      []
    end
  end
  
end
