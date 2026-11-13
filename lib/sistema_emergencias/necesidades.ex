defmodule SistemaEmergencias.Necesidades do
  @prioridades [:critica, :alta, :media, :baja]
  @estados [:pendiente, :asignada, :en_atencion, :atendida, :cancelada]

  def registrar(necesidad, necesidades)
      when is_map(necesidad) and is_list(necesidades) do
    id = Map.get(necesidad, :id)
    tipo = Map.get(necesidad, :tipo)
    descripcion = Map.get(necesidad, :descripcion)
    cantidad = Map.get(necesidad, :cantidad)
    zona = Map.get(necesidad, :zona)
    prioridad = normalizar_prioridad(Map.get(necesidad, :prioridad))
    responsable = Map.get(necesidad, :responsable)

    with {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(id),
         {:ok, tipo} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(tipo),
         {:ok, descripcion} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(descripcion),
         {:ok, zona} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(zona),
         :ok <- validar_cantidad(cantidad),
         :ok <- validar_prioridad(prioridad),
         :ok <- validar_id_unico(id, necesidades) do
      nueva = %{
        id: id,
        tipo: tipo,
        descripcion: descripcion,
        cantidad: cantidad,
        zona: zona,
        prioridad: prioridad,
        responsable: responsable,
        estado: :pendiente
      }

      {:ok, nueva, [nueva | necesidades]}
    end
  end

  def registrar(_, _), do: {:error, "Los datos de la necesidad no son válidos"}

  def buscar(id, necesidades) when is_list(necesidades) do
    case Enum.find(necesidades, fn necesidad -> necesidad.id == id end) do
      nil -> {:error, "No se encontró la necesidad"}
      necesidad -> {:ok, necesidad}
    end
  end

  def listar(necesidades) when is_list(necesidades), do: necesidades

  def ordenar_por_prioridad(necesidades) when is_list(necesidades) do
    orden = %{critica: 1, alta: 2, media: 3, baja: 4}

    Enum.sort_by(necesidades, fn necesidad ->
      Map.get(orden, necesidad.prioridad, 5)
    end)
  end

  def asignar(id, responsable, necesidades) when is_list(necesidades) do
    with {:ok, necesidad} <- buscar(id, necesidades),
         {:ok, responsable} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(responsable),
         :ok <- validar_transicion(necesidad.estado, :asignada) do
      actualizar_necesidad(necesidad, %{estado: :asignada, responsable: responsable}, necesidades)
    end
  end

  def cambiar_estado(id, nuevo_estado, necesidades) when is_list(necesidades) do
    nuevo_estado = normalizar_estado(nuevo_estado)

    with {:ok, necesidad} <- buscar(id, necesidades),
         :ok <- validar_estado(nuevo_estado),
         :ok <- validar_transicion(necesidad.estado, nuevo_estado) do
      actualizar_necesidad(necesidad, %{estado: nuevo_estado}, necesidades)
    end
  end

  def filtrar_por_estado(estado, necesidades) when is_list(necesidades) do
    estado = normalizar_estado(estado)

    Enum.filter(necesidades, fn necesidad ->
      necesidad.estado == estado
    end)
  end

  def filtrar_por_zona(zona, necesidades) when is_list(necesidades) do
    Enum.filter(necesidades, fn necesidad ->
      necesidad.zona == zona
    end)
  end

  defp actualizar_necesidad(necesidad, cambios, necesidades) do
    actualizada = Map.merge(necesidad, cambios)

    lista_actualizada =
      Enum.map(necesidades, fn elemento ->
        if elemento.id == necesidad.id, do: actualizada, else: elemento
      end)

    {:ok, actualizada, lista_actualizada}
  end

  defp validar_cantidad(cantidad) when is_integer(cantidad) and cantidad > 0, do: :ok

  defp validar_cantidad(_),
    do: {:error, "La cantidad solicitada debe ser un entero mayor que cero"}

  defp validar_id_unico(id, necesidades) do
    if Enum.any?(necesidades, fn necesidad -> necesidad.id == id end) do
      {:error, "Ya existe una necesidad con ese ID"}
    else
      :ok
    end
  end

  defp validar_prioridad(prioridad) do
    if prioridad in @prioridades do
      :ok
    else
      {:error, "La prioridad debe ser crítica, alta, media o baja"}
    end
  end

  defp normalizar_prioridad(valor) when is_atom(valor), do: valor

  defp normalizar_prioridad(valor) when is_binary(valor) do
    case String.downcase(String.trim(valor)) do
      "critica" -> :critica
      "crítica" -> :critica
      "alta" -> :alta
      "media" -> :media
      "baja" -> :baja
      _ -> :desconocida
    end
  end

  defp normalizar_prioridad(_), do: :desconocida

  defp validar_estado(estado) do
    if estado in @estados do
      :ok
    else
      {:error, "El estado indicado no es válido"}
    end
  end

  defp normalizar_estado(valor) when is_atom(valor), do: valor

  defp normalizar_estado(valor) when is_binary(valor) do
    case String.downcase(String.trim(valor)) do
      "pendiente" -> :pendiente
      "asignada" -> :asignada
      "en_atencion" -> :en_atencion
      "atendida" -> :atendida
      "cancelada" -> :cancelada
      _ -> :desconocido
    end
  end

  defp normalizar_estado(_), do: :desconocido

  defp validar_transicion(actual, nuevo) do
    permitidas = %{
      pendiente: [:asignada, :cancelada],
      asignada: [:en_atencion, :cancelada],
      en_atencion: [:atendida, :cancelada],
      atendida: [],
      cancelada: []
    }

    if nuevo in Map.get(permitidas, actual, []) do
      :ok
    else
      {:error, "No se permite cambiar del estado #{actual} a #{nuevo}"}
    end
  end
end
