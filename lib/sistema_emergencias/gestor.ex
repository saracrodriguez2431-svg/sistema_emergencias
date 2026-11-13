defmodule SistemaEmergencias.Gestor do
  alias SistemaEmergencias.Almacenamiento

  @doc "Crea el estado inicial con todas las colecciones vacías."
  def estado_inicial do
    Map.new(Almacenamiento.colecciones(), fn nombre ->
      {nombre, []}
    end)
  end

  @doc "Inicia el sistema recuperando los datos guardados."
  def iniciar do
    case Almacenamiento.cargar_todo() do
      {:ok, datos} ->
        {:ok, Map.merge(estado_inicial(), datos)}

      {:error, razon} ->
        {:error, razon}
    end
  end

  @doc "Guarda todas las colecciones del sistema."
  def guardar(estado) do
    Almacenamiento.guardar_todo(estado)
  end

  @doc "Actualiza una colección y persiste el cambio."
  def actualizar(estado, coleccion, datos) do
    Almacenamiento.actualizar(estado, coleccion, datos)
  end

  @doc "Genera un resumen de los registros del sistema."
  def resumen(estado) do
    Map.new(Almacenamiento.colecciones(), fn nombre ->
      {nombre, length(Map.get(estado, nombre, []))}
    end)
  end
end
