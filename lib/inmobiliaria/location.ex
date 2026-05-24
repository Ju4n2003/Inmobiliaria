defmodule Inmobiliaria.Location do
  @moduledoc """
  Maneja las ubicaciones válidas del sistema
  """

  @archivo_ubicaciones "locations.dat"

  def listar() do
    case File.read(@archivo_ubicaciones) do
      {:ok, contents} ->
        String.split(contents, ~r/\R/, trim: true)

      {:error, _reason} ->
        []
    end
  end

  def validar?(ubicacion) do
    ubicacion =
      ubicacion
      |> String.trim()
      |> String.downcase()

    listar()
    |> Enum.any?(fn ciudad ->
      String.downcase(ciudad) == ubicacion
    end)
  end
end
