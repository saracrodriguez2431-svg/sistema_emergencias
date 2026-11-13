defmodule SistemaEmergencias.Mascotas do
  @tipos [:perdida, :encontrada]

  def registrar(reporte, reportes) when is_map(reporte) and is_list(reportes) do
    campos = [:id, :especie, :color, :tamano, :zona, :contacto]

    with :ok <- validar_campos(reporte, campos),
         :ok <- validar_id_unico(Map.get(reporte, :id), reportes),
         tipo <- normalizar_tipo(Map.get(reporte, :tipo)),
         :ok <- validar_tipo(tipo) do
      nuevo = %{
        id: reporte.id,
        tipo: tipo,
        especie: normalizar_texto(reporte.especie),
        nombre: normalizar_texto(Map.get(reporte, :nombre, "")),
        caracteristicas: normalizar_texto(Map.get(reporte, :caracteristicas, "")),
        color: normalizar_texto(reporte.color),
        tamano: normalizar_texto(reporte.tamano),
        zona: normalizar_texto(reporte.zona),
        contacto: reporte.contacto,
        estado: :activa,
        fecha: DateTime.utc_now()
      }

      {:ok, nuevo, [nuevo | reportes]}
    end
  end

  def registrar(_, _), do: {:error, "Los datos del reporte no son válidos"}

  def buscar(id, reportes) when is_list(reportes) do
    case Enum.find(reportes, fn reporte -> reporte.id == id end) do
      nil -> {:error, "No se encontró el reporte"}
      reporte -> {:ok, reporte}
    end
  end

  def listar(reportes) when is_list(reportes), do: reportes

  def posibles_coincidencias(id, reportes) when is_list(reportes) do
    with {:ok, reporte} <- buscar(id, reportes),
         true <- reporte.estado == :activa do
      coincidencias =
        reportes
        |> Enum.filter(fn otro ->
          otro.id != reporte.id and
            otro.estado == :activa and
            otro.tipo != reporte.tipo
        end)
        |> Enum.map(fn otro ->
          %{reporte: otro, puntaje: calcular_similitud(reporte, otro)}
        end)
        |> Enum.filter(fn resultado -> resultado.puntaje >= 60 end)
        |> Enum.sort_by(fn resultado -> resultado.puntaje end, :desc)

      {:ok, coincidencias}
    else
      false -> {:error, "El reporte no está activo"}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def confirmar_coincidencia(id1, id2, reportes) when is_list(reportes) do
    with {:ok, reporte1} <- buscar(id1, reportes),
         {:ok, reporte2} <- buscar(id2, reportes),
         true <- reporte1.tipo != reporte2.tipo,
         true <- reporte1.estado in [:activa, :posible_coincidencia],
         true <- reporte2.estado in [:activa, :posible_coincidencia] do
      actualizados =
        Enum.map(reportes, fn reporte ->
          if reporte.id in [id1, id2] do
            %{reporte | estado: :resuelta}
          else
            reporte
          end
        end)

      {:ok, actualizados}
    else
      false -> {:error, "Los reportes no pueden vincularse o ya fueron resueltos"}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def calcular_similitud(reporte1, reporte2) do
    puntaje =
      comparar(reporte1.especie, reporte2.especie, 30) +
        comparar(reporte1.color, reporte2.color, 20) +
        comparar(reporte1.tamano, reporte2.tamano, 15) +
        comparar(reporte1.zona, reporte2.zona, 20) +
        comparar(reporte1.nombre, reporte2.nombre, 10) +
        comparar(reporte1.caracteristicas, reporte2.caracteristicas, 5)

    puntaje
  end

  defp comparar(valor, valor, peso) when valor != "", do: peso
  defp comparar(_, _, _), do: 0

  defp validar_campos(reporte, campos) do
    Enum.reduce_while(campos, :ok, fn campo, _ ->
      case SistemaEmergencias.Validaciones.texto_obligatorio(Map.get(reporte, campo)) do
        {:ok, _} -> {:cont, :ok}
        {:error, motivo} -> {:halt, {:error, "Campo #{campo}: #{motivo}"}}
      end
    end)
  end

  defp validar_id_unico(id, reportes) do
    if Enum.any?(reportes, fn reporte -> reporte.id == id end) do
      {:error, "Ya existe un reporte con ese ID"}
    else
      :ok
    end
  end

  defp validar_tipo(tipo) do
    if tipo in @tipos do
      :ok
    else
      {:error, "El tipo debe ser perdida o encontrada"}
    end
  end

  defp normalizar_tipo(valor) when is_atom(valor), do: valor

  defp normalizar_tipo(valor) when is_binary(valor) do
    case String.downcase(String.trim(valor)) do
      "perdida" -> :perdida
      "perdida " -> :perdida
      "encontrada" -> :encontrada
      _ -> :desconocido
    end
  end

  defp normalizar_tipo(_), do: :desconocido

  defp normalizar_texto(valor) when is_binary(valor) do
    valor |> String.trim() |> String.downcase()
  end

  defp normalizar_texto(_), do: ""
end
