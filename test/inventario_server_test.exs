defmodule SistemaEmergencias.InventarioServerTest do
  use ExUnit.Case, async: false

  alias SistemaEmergencias.InventarioServer

  test "registra entradas y salidas del inventario" do
    recurso = %{codigo: "R1", nombre: "Agua", cantidad: 20, historial: []}
    {:ok, servidor} = InventarioServer.start_link([recurso])

    assert {:ok, actualizado} = InventarioServer.salida(servidor, "R1", 5)
    assert actualizado.cantidad == 15

    assert {:ok, actualizado} = InventarioServer.entrada(servidor, "R1", 3)
    assert actualizado.cantidad == 18

    GenServer.stop(servidor)
  end

  test "rechaza una salida que supera el inventario" do
    recurso = %{codigo: "R1", nombre: "Agua", cantidad: 10, historial: []}
    {:ok, servidor} = InventarioServer.start_link([recurso])

    assert {:error, _} = InventarioServer.salida(servidor, "R1", 15)
    assert {:ok, [recurso_actual]} = InventarioServer.consultar(servidor)
    assert recurso_actual.cantidad == 10

    GenServer.stop(servidor)
  end

  test "evita que dos retiros simultáneos superen las existencias" do
    recurso = %{codigo: "R1", nombre: "Agua", cantidad: 10, historial: []}
    {:ok, servidor} = InventarioServer.start_link([recurso])

    tarea1 = Task.async(fn -> InventarioServer.salida(servidor, "R1", 7) end)
    tarea2 = Task.async(fn -> InventarioServer.salida(servidor, "R1", 7) end)

    resultados = [Task.await(tarea1), Task.await(tarea2)]

    exitos =
      Enum.count(resultados, fn resultado ->
        match?({:ok, _}, resultado)
      end)

    errores =
      Enum.count(resultados, fn resultado ->
        match?({:error, _}, resultado)
      end)

    assert exitos == 1
    assert errores == 1

    assert {:ok, [recurso_final]} = InventarioServer.consultar(servidor)
    assert recurso_final.cantidad == 3

    GenServer.stop(servidor)
  end
end
