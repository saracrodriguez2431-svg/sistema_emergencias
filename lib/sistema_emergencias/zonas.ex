defmodule SistemaEmergencias.Zonas do
  @niveles [:critico, :alto, :medio, :bajo]

  def registrar_zona(zona, zonas) when is_map(zona) and is_list(zonas) do
    with {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(zona, :id)),
         {:ok, nombre} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(zona, :nombre)),
         :ok <- validar_nivel(Map.get(zona, :nivel)),
         :ok <- validar_id_zona(id, zonas) do
      nueva_zona = %{
        id: id,
        nombre: nombre,
        nivel: normalizar_nivel(Map.get(zona, :nivel)),
        sectores: []
      }

      {:ok, nueva_zona, [nueva_zona | zonas]}
    end
  end

  def registrar_zona(_, _), do: {:error, "Los datos de la zona no son válidos"}

  def agregar_sector(zona_id, sector, zonas)
      when is_map(sector) and is_list(zonas) do
    with {:ok, zona} <- buscar_zona(zona_id, zonas),
         {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(sector, :id)),
         {:ok, nombre} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(sector, :nombre)),
         :ok <- validar_id_sector(id, zona.sectores) do
      nuevo_sector = %{
        id: id,
        nombre: nombre,
        puntos: []
      }

      zona_actualizada = %{zona | sectores: [nuevo_sector | zona.sectores]}

      zonas_actualizadas =
        Enum.map(zonas, fn elemento ->
          if elemento.id == zona_id, do: zona_actualizada, else: elemento
        end)

      {:ok, nuevo_sector, zonas_actualizadas}
    end
  end

  def agregar_sector(_, _, _), do: {:error, "Los datos del sector no son válidos"}

  def agregar_punto(zona_id, sector_id, punto, zonas)
      when is_map(punto) and is_list(zonas) do
    with {:ok, zona} <- buscar_zona(zona_id, zonas),
         {:ok, sector} <- buscar_sector(sector_id, zona.sectores),
         {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(punto, :id)),
         {:ok, nombre} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(punto, :nombre)),
         :ok <- validar_id_punto(id, zonas) do
      nuevo_punto = %{
        id: id,
        nombre: nombre,
        direccion: Map.get(punto, :direccion, ""),
        estado: Map.get(punto, :estado, :activo)
      }

      sector_actualizado = %{sector | puntos: [nuevo_punto | sector.puntos]}

      sectores_actualizados =
        Enum.map(zona.sectores, fn elemento ->
          if elemento.id == sector_id, do: sector_actualizado, else: elemento
        end)

      zona_actualizada = %{zona | sectores: sectores_actualizados}

      zonas_actualizadas =
        Enum.map(zonas, fn elemento ->
          if elemento.id == zona_id, do: zona_actualizada, else: elemento
        end)

      {:ok, nuevo_punto, zonas_actualizadas}
    end
  end

  def agregar_punto(_, _, _, _), do: {:error, "Los datos del punto no son válidos"}

  def buscar_zona(id, zonas) when is_list(zonas) do
    case Enum.find(zonas, fn zona -> zona.id == id end) do
      nil -> {:error, "No se encontró la zona"}
      zona -> {:ok, zona}
    end
  end

  def buscar_sector(id, sectores) when is_list(sectores) do
    case Enum.find(sectores, fn sector -> sector.id == id end) do
      nil -> {:error, "No se encontró el sector"}
      sector -> {:ok, sector}
    end
  end

  def listar_zonas(zonas) when is_list(zonas), do: zonas

  def contar_sectores(zonas) when is_list(zonas) do
    contar_sectores_recursivo(zonas, 0)
  end

  def contar_puntos(zonas) when is_list(zonas) do
    contar_puntos_zonas(zonas, 0)
  end

  def listar_puntos(zonas) when is_list(zonas) do
    listar_puntos_zonas(zonas, [])
  end

  defp validar_nivel(nivel) do
    if normalizar_nivel(nivel) in @niveles do
      :ok
    else
      {:error, "El nivel de emergencia debe ser crítico, alto, medio o bajo"}
    end
  end

  defp normalizar_nivel(nivel) when is_atom(nivel), do: nivel

  defp normalizar_nivel(nivel) when is_binary(nivel) do
    case String.downcase(String.trim(nivel)) do
      "critico" -> :critico
      "crítico" -> :critico
      "alto" -> :alto
      "medio" -> :medio
      "bajo" -> :bajo
      _ -> :desconocido
    end
  end

  defp normalizar_nivel(_), do: :desconocido

  defp validar_id_zona(id, zonas) do
    if Enum.any?(zonas, fn zona -> zona.id == id end) do
      {:error, "Ya existe una zona con ese ID"}
    else
      :ok
    end
  end

  defp validar_id_sector(id, sectores) do
    if Enum.any?(sectores, fn sector -> sector.id == id end) do
      {:error, "Ya existe un sector con ese ID en la zona"}
    else
      :ok
    end
  end

  defp validar_id_punto(id, zonas) do
    puntos = listar_puntos(zonas)

    if Enum.any?(puntos, fn punto -> punto.id == id end) do
      {:error, "Ya existe un punto de atención con ese ID"}
    else
      :ok
    end
  end

  # Recorre recursivamente todas las zonas y sus sectores.
  defp contar_sectores_recursivo([], total), do: total

  defp contar_sectores_recursivo([zona | resto], total) do
    contar_sectores_recursivo(resto, total + length(zona.sectores))
  end

  # Recorre recursivamente las zonas y después los sectores de cada zona.
  defp contar_puntos_zonas([], total), do: total

  defp contar_puntos_zonas([zona | resto], total) do
    cantidad = contar_puntos_sectores(zona.sectores, 0)
    contar_puntos_zonas(resto, total + cantidad)
  end

  defp contar_puntos_sectores([], total), do: total

  defp contar_puntos_sectores([sector | resto], total) do
    contar_puntos_sectores(resto, total + length(sector.puntos))
  end

  # Construye una lista con los puntos de atención de todas las zonas.
  defp listar_puntos_zonas([], acumulados), do: acumulados

  defp listar_puntos_zonas([zona | resto], acumulados) do
    puntos = listar_puntos_sectores(zona.sectores, [])
    listar_puntos_zonas(resto, acumulados ++ puntos)
  end

  defp listar_puntos_sectores([], acumulados), do: acumulados

  defp listar_puntos_sectores([sector | resto], acumulados) do
    listar_puntos_sectores(resto, acumulados ++ sector.puntos)
  end
end
