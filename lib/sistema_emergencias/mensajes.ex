defmodule SistemaEmergencias.Mensajes do
  @estados [:enviado, :entregado, :leido, :fallido]

  def enviar(mensaje, mensajes) when is_map(mensaje) and is_list(mensajes) do
    id = Map.get(mensaje, :id)
    remitente = Map.get(mensaje, :remitente)
    destinatario = Map.get(mensaje, :destinatario)
    contenido = Map.get(mensaje, :contenido)

    with {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(id),
         {:ok, remitente} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(remitente),
         {:ok, destinatario} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(destinatario),
         {:ok, contenido} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(contenido),
         :ok <- validar_id_unico(id, mensajes) do
      nuevo = %{
        id: id,
        remitente: remitente,
        destinatario: destinatario,
        contenido: contenido,
        fecha: DateTime.utc_now(),
        estado: :enviado
      }

      {:ok, nuevo, [nuevo | mensajes]}
    end
  end

  def enviar(_, _), do: {:error, "Los datos del mensaje no son válidos"}

  def buscar(id, mensajes) when is_list(mensajes) do
    case Enum.find(mensajes, fn mensaje -> mensaje.id == id end) do
      nil -> {:error, "No se encontró el mensaje"}
      mensaje -> {:ok, mensaje}
    end
  end

  def listar(mensajes) when is_list(mensajes), do: mensajes

  def historial_usuario(usuario_id, mensajes) when is_list(mensajes) do
    Enum.filter(mensajes, fn mensaje ->
      mensaje.remitente == usuario_id or mensaje.destinatario == usuario_id
    end)
  end

  def recibidos(usuario_id, mensajes) when is_list(mensajes) do
    Enum.filter(mensajes, fn mensaje ->
      mensaje.destinatario == usuario_id
    end)
  end

  def actualizar_estado(id, nuevo_estado, mensajes) when is_list(mensajes) do
    nuevo_estado = normalizar_estado(nuevo_estado)

    with {:ok, mensaje} <- buscar(id, mensajes),
         :ok <- validar_estado(nuevo_estado),
         :ok <- validar_transicion(mensaje.estado, nuevo_estado) do
      actualizado = %{mensaje | estado: nuevo_estado}

      mensajes_actualizados =
        Enum.map(mensajes, fn elemento ->
          if elemento.id == id, do: actualizado, else: elemento
        end)

      {:ok, actualizado, mensajes_actualizados}
    end
  end

  defp validar_id_unico(id, mensajes) do
    if Enum.any?(mensajes, fn mensaje -> mensaje.id == id end) do
      {:error, "Ya existe un mensaje con ese ID"}
    else
      :ok
    end
  end

  defp validar_estado(estado) do
    if estado in @estados do
      :ok
    else
      {:error, "El estado del mensaje no es válido"}
    end
  end

  defp normalizar_estado(valor) when is_atom(valor), do: valor

  defp normalizar_estado(valor) when is_binary(valor) do
    case String.downcase(String.trim(valor)) do
      "enviado" -> :enviado
      "entregado" -> :entregado
      "leido" -> :leido
      "leído" -> :leido
      "fallido" -> :fallido
      _ -> :desconocido
    end
  end

  defp normalizar_estado(_), do: :desconocido

  defp validar_transicion(:enviado, nuevo)
       when nuevo in [:entregado, :fallido], do: :ok

  defp validar_transicion(:entregado, :leido), do: :ok

  defp validar_transicion(actual, nuevo) do
    {:error, "No se permite cambiar el mensaje de #{actual} a #{nuevo}"}
  end
end
