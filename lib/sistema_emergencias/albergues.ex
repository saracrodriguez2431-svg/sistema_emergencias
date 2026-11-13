defmodule SistemaEmergencias.Albergues do
  def registrar(albergue, albergues)
      when is_map(albergue) and is_list(albergues) do
    id = Map.get(albergue, :id)
    nombre = Map.get(albergue, :nombre)
    zona = Map.get(albergue, :zona)
    capacidad = Map.get(albergue, :capacidad)

    with {:ok, id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(id),
         {:ok, nombre} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(nombre),
         {:ok, zona} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(zona),
         :ok <- validar_capacidad(capacidad),
         :ok <- validar_id_unico(id, albergues) do
      nuevo = %{
        id: id,
        nombre: nombre,
        zona: zona,
        capacidad: capacidad,
        ocupacion: 0,
        recursos: [],
        necesidades: []
      }

      {:ok, nuevo, [nuevo | albergues]}
    end
  end

  def registrar(_, _), do: {:error, "Los datos del albergue no son válidos"}

  def buscar(id, albergues) when is_list(albergues) do
    case Enum.find(albergues, fn albergue -> albergue.id == id end) do
      nil -> {:error, "No se encontró el albergue"}
      albergue -> {:ok, albergue}
    end
  end

  def listar(albergues) when is_list(albergues), do: albergues

  def ingresar_personas(id, cantidad, albergues) when is_list(albergues) do
    with :ok <- validar_cantidad(cantidad),
         {:ok, albergue} <- buscar(id, albergues),
         :ok <- validar_cupo(albergue, cantidad) do
      actualizar(albergue, %{ocupacion: albergue.ocupacion + cantidad}, albergues)
    end
  end

  def retirar_personas(id, cantidad, albergues) when is_list(albergues) do
    with :ok <- validar_cantidad(cantidad),
         {:ok, albergue} <- buscar(id, albergues),
         :ok <- validar_ocupacion(albergue, cantidad) do
      actualizar(albergue, %{ocupacion: albergue.ocupacion - cantidad}, albergues)
    end
  end

  def asociar_recurso(id, codigo, albergues) when is_list(albergues) do
    with {:ok, codigo} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(codigo),
         {:ok, albergue} <- buscar(id, albergues) do
      if codigo in albergue.recursos do
        {:error, "El recurso ya está asociado al albergue"}
      else
        actualizar(
          albergue,
          %{recursos: [codigo | albergue.recursos]},
          albergues
        )
      end
    end
  end

  def asociar_necesidad(id, necesidad_id, albergues) when is_list(albergues) do
    with {:ok, necesidad_id} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(necesidad_id),
         {:ok, albergue} <- buscar(id, albergues) do
      if necesidad_id in albergue.necesidades do
        {:error, "La necesidad ya está asociada al albergue"}
      else
        actualizar(
          albergue,
          %{necesidades: [necesidad_id | albergue.necesidades]},
          albergues
        )
      end
    end
  end

  def porcentaje_ocupacion(albergue) when is_map(albergue) do
    albergue.ocupacion / albergue.capacidad * 100
  end

  def mayor_ocupacion(albergues) when is_list(albergues) do
    case albergues do
      [] -> {:error, "No hay albergues registrados"}
      _ -> {:ok, Enum.max_by(albergues, &porcentaje_ocupacion/1)}
    end
  end

  defp actualizar(albergue, cambios, albergues) do
    actualizado = Map.merge(albergue, cambios)

    lista_actualizada =
      Enum.map(albergues, fn elemento ->
        if elemento.id == albergue.id, do: actualizado, else: elemento
      end)

    {:ok, actualizado, lista_actualizada}
  end

  defp validar_capacidad(capacidad)
       when is_integer(capacidad) and capacidad > 0,
       do: :ok

  defp validar_capacidad(_),
    do: {:error, "La capacidad debe ser un entero mayor que cero"}

  defp validar_cantidad(cantidad)
       when is_integer(cantidad) and cantidad > 0,
       do: :ok

  defp validar_cantidad(_),
    do: {:error, "La cantidad debe ser un entero mayor que cero"}

  defp validar_id_unico(id, albergues) do
    if Enum.any?(albergues, fn albergue -> albergue.id == id end) do
      {:error, "Ya existe un albergue con ese ID"}
    else
      :ok
    end
  end

  defp validar_cupo(albergue, cantidad) do
    if albergue.ocupacion + cantidad <= albergue.capacidad do
      :ok
    else
      {:error, "El albergue no tiene suficientes cupos disponibles"}
    end
  end

  defp validar_ocupacion(albergue, cantidad) do
    if cantidad <= albergue.ocupacion do
      :ok
    else
      {:error, "No se pueden retirar más personas de las que están alojadas"}
    end
  end
end
