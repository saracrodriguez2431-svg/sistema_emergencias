defmodule SistemaEmergencias.Personas do
  @estados [:desaparecida, :localizada, :hospitalizada, :fallecida, :sin_confirmar]

  def registrar(persona, personas) when is_map(persona) and is_list(personas) do
    id = Map.get(persona, :id)
    nombre = Map.get(persona, :nombre)
    documento = Map.get(persona, :documento)
    edad = Map.get(persona, :edad)
    zona = Map.get(persona, :zona)
    estado = normalizar_estado(Map.get(persona, :estado, :sin_confirmar))

    with {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(id),
         {:ok, nombre} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(nombre),
         {:ok, documento} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(documento),
         {:ok, zona} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(zona),
         :ok <- validar_edad(edad),
         :ok <- validar_estado(estado),
         :ok <- validar_id_unico(id, personas),
         :ok <- validar_documento_unico(documento, personas) do
      nueva = %{
        id: id,
        nombre: nombre,
        documento: documento,
        edad: edad,
        zona: zona,
        estado: estado,
        historial: [
          %{estado: estado, fecha: DateTime.utc_now()}
        ]
      }

      {:ok, nueva, [nueva | personas]}
    end
  end

  def registrar(_, _), do: {:error, "Los datos de la persona no son válidos"}

  def buscar(id, personas) when is_list(personas) do
    case Enum.find(personas, fn persona -> persona.id == id end) do
      nil -> {:error, "No se encontró la persona"}
      persona -> {:ok, persona}
    end
  end

  def buscar_por_documento(documento, personas) when is_list(personas) do
    case Enum.find(personas, fn persona ->
           persona.documento == documento
         end) do
      nil -> {:error, "No se encontró una persona con ese documento"}
      persona -> {:ok, persona}
    end
  end

  def listar(personas) when is_list(personas), do: personas

  def actualizar_estado(id, nuevo_estado, personas) when is_list(personas) do
    nuevo_estado = normalizar_estado(nuevo_estado)

    with {:ok, persona} <- buscar(id, personas),
         :ok <- validar_estado(nuevo_estado) do
      cambio = %{
        estado: nuevo_estado,
        fecha: DateTime.utc_now()
      }

      actualizada = %{
        persona
        | estado: nuevo_estado,
          historial: [cambio | persona.historial]
      }

      personas_actualizadas =
        Enum.map(personas, fn elemento ->
          if elemento.id == id, do: actualizada, else: elemento
        end)

      {:ok, actualizada, personas_actualizadas}
    end
  end

  def filtrar_por_zona(zona, personas) when is_list(personas) do
    Enum.filter(personas, fn persona -> persona.zona == zona end)
  end

  def filtrar_por_estado(estado, personas) when is_list(personas) do
    estado = normalizar_estado(estado)

    Enum.filter(personas, fn persona -> persona.estado == estado end)
  end

  defp validar_edad(edad) when is_integer(edad) and edad >= 0, do: :ok
  defp validar_edad(_), do: {:error, "La edad debe ser un entero no negativo"}

  defp validar_estado(estado) do
    if estado in @estados do
      :ok
    else
      {:error, "El estado de la persona no es válido"}
    end
  end

  defp normalizar_estado(valor) when is_atom(valor), do: valor

  defp normalizar_estado(valor) when is_binary(valor) do
    case String.downcase(String.trim(valor)) do
      "desaparecida" -> :desaparecida
      "localizada" -> :localizada
      "hospitalizada" -> :hospitalizada
      "fallecida" -> :fallecida
      "sin_confirmar" -> :sin_confirmar
      _ -> :desconocido
    end
  end

  defp normalizar_estado(_), do: :desconocido

  defp validar_id_unico(id, personas) do
    if Enum.any?(personas, fn persona -> persona.id == id end) do
      {:error, "Ya existe una persona con ese ID"}
    else
      :ok
    end
  end

  defp validar_documento_unico(documento, personas) do
    if Enum.any?(personas, fn persona -> persona.documento == documento end) do
      {:error, "Ya existe una persona con ese documento"}
    else
      :ok
    end
  end
end
