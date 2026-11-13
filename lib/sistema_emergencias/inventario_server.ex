defmodule SistemaEmergencias.InventarioServer do
  use GenServer

  @moduledoc """
  Administra el inventario mediante un proceso GenServer.
  Las operaciones se ejecutan de forma secuencial para evitar
  retiros simultáneos que superen las existencias.
  """

  def start_link(recursos \\ []) do
    GenServer.start_link(__MODULE__, recursos)
  end

  def consultar(servidor) do
    GenServer.call(servidor, :consultar)
  end

  def salida(servidor, codigo, cantidad) do
    GenServer.call(servidor, {:salida, codigo, cantidad})
  end

  def entrada(servidor, codigo, cantidad) do
    GenServer.call(servidor, {:entrada, codigo, cantidad})
  end

  @impl true
  def init(recursos) do
    inventario =
      Map.new(recursos, fn recurso ->
        {recurso.codigo, recurso}
      end)

    {:ok, inventario}
  end

  @impl true
  def handle_call(:consultar, _desde, inventario) do
    {:reply, {:ok, Map.values(inventario)}, inventario}
  end

  def handle_call({operacion, codigo, cantidad}, _desde, inventario)
      when operacion in [:salida, :entrada] do
    with true <- is_integer(cantidad) and cantidad > 0,
         {:ok, recurso} <- Map.fetch(inventario, codigo),
         {:ok, actualizado} <- actualizar_recurso(recurso, operacion, cantidad) do
      nuevo_inventario = Map.put(inventario, codigo, actualizado)
      {:reply, {:ok, actualizado}, nuevo_inventario}
    else
      false ->
        {:reply, {:error, "La cantidad debe ser un entero mayor que cero"}, inventario}

      :error ->
        {:reply, {:error, "El recurso no existe"}, inventario}

      {:error, mensaje} ->
        {:reply, {:error, mensaje}, inventario}
    end
  end

  defp actualizar_recurso(recurso, :salida, cantidad) do
    if recurso.cantidad >= cantidad do
      nuevo = %{
        recurso
        | cantidad: recurso.cantidad - cantidad,
          historial:
            Map.get(recurso, :historial, []) ++
              [%{tipo: :salida, cantidad: cantidad, fecha: DateTime.utc_now()}]
      }

      {:ok, nuevo}
    else
      {:error, "Inventario insuficiente para realizar la salida"}
    end
  end

  defp actualizar_recurso(recurso, :entrada, cantidad) do
    nuevo = %{
      recurso
      | cantidad: recurso.cantidad + cantidad,
        historial:
          Map.get(recurso, :historial, []) ++
            [%{tipo: :entrada, cantidad: cantidad, fecha: DateTime.utc_now()}]
    }

    {:ok, nuevo}
  end
end
