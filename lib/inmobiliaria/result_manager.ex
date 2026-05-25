defmodule Inmobiliaria.ResultManager do
  def guardar_operacion(
        cliente,
        responsable,
        propiedad_id,
        operacion,
        ubicacion,
        precio
      ) do
    fecha =
      Date.utc_today()
      |> Date.to_string()

    linea =
      "#{fecha};cliente=#{cliente};responsable=#{responsable};" <>
        "propiedad=#{propiedad_id};operacion=#{operacion};" <>
        "ubicacion=#{ubicacion};precio=#{precio};status=Completada\n"

    File.write!(
      "data/results.log",
      linea,
      [:append]
    )
  end
end
