defmodule SistemaEmergencias.Almacenamiento do
  alias SistemaEmergencias.Persistencia

  @colecciones [
    :usuarios,
    :zonas,
    :necesidades,
    :recursos,
    :personas,
    :mensajes,
    :mascotas,
    :albergues
  ]

  @doc "Carga todas las colecciones guardadas en archivos."
  def cargar_todo do
    Enum.reduce_while(@colecciones, {:ok, %{}}, fn nombre, {:ok, estado} ->
      case Persistencia.cargar(nombre) do
        {:ok, datos} ->
          {:cont, {:ok, Map.put(estado, nombre, datos)}}

        {:error, razon} ->
          {:halt, {:error, "Error cargando #{nombre}: #{razon}"}}
      end
    end)
  end

  @doc "Guarda todas las colecciones del estado en sus archivos."
  def guardar_todo(estado) when is_map(estado) do
    Enum.reduce_while(@colecciones, {:ok, "Todas las colecciones fueron guardadas"}, fn nombre,
                                                                                        resultado ->
      case Map.fetch(estado, nombre) do
        {:ok, datos} ->
          case Persistencia.guardar(nombre, datos) do
            {:ok, _mensaje} -> {:cont, resultado}
            {:error, razon} -> {:halt, {:error, "Error guardando #{nombre}: #{razon}"}}
          end

        :error ->
          {:halt, {:error, "Falta la colección #{nombre} en el estado"}}
      end
    end)
  end

  def guardar_todo(_estado) do
    {:error, "El estado debe ser un mapa"}
  end

  @doc "Actualiza una colección y guarda el cambio."
  def actualizar(estado, nombre, nuevos_datos)
      when is_map(estado) and nombre in @colecciones and is_list(nuevos_datos) do
    nuevo_estado = Map.put(estado, nombre, nuevos_datos)

    case Persistencia.guardar(nombre, nuevos_datos) do
      {:ok, _mensaje} -> {:ok, nuevo_estado}
      {:error, razon} -> {:error, razon}
    end
  end

  def actualizar(_estado, _nombre, _nuevos_datos) do
    {:error, "Colección o datos no válidos"}
  end

  def colecciones, do: @colecciones
end
