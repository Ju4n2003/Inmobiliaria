defmodule Inmobiliaria.MessageManager do

  @archivo_mensajes "data/messages.log"

  def enviar_mensaje(propiedad_id,usuario,mensaje) do

    fecha = Date.utc_today()

    linea =
      "#{fecha};" <>
      "propiedad=#{propiedad_id};" <>
      "usuario=#{usuario};" <>
      "mensaje=#{mensaje}\n"

    File.write!(
      @archivo_mensajes,
      linea,
      [:append]
    )

    IO.puts("Mensaje enviado")
  end

  def ver_mensajes() do

    if File.exists?(@archivo_mensajes) do

      contenido = File.read!(@archivo_mensajes)

      String.split(
        contenido,
        "\n",
        trim: true
      )

    else
      []
    end
  end
end
