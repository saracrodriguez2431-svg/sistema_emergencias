defmodule SistemaEmergencias.RecursosTest do
  use ExUnit.Case

  alias SistemaEmergencias.Recursos

  @recurso %{
    codigo: "R001",
    nombre: "Agua potable",
    categoria: "Alimentos y bebidas",
    cantidad: 100,
    unidad: "litros",
    ubicacion: "Bodega central"
  }

  test "registra un recurso correctamente" do
    assert {:ok, recurso, [recurso]} = Recursos.registrar(@recurso, [])

    assert recurso.cantidad == 100
    assert recurso.ubicacion == "Bodega central"
    assert length(recurso.historial) == 1
  end

  test "rechaza cantidades negativas o iguales a cero" do
    assert {:error, _} =
             Recursos.registrar(%{@recurso | cantidad: -10}, [])

    assert {:error, _} =
             Recursos.registrar(%{@recurso | cantidad: 0}, [])
  end

  test "no permite códigos repetidos" do
    assert {:ok, _, recursos} = Recursos.registrar(@recurso, [])
    assert {:error, _} = Recursos.registrar(@recurso, recursos)
  end

  test "registra una entrada de recursos" do
    assert {:ok, _, recursos} = Recursos.registrar(@recurso, [])
    assert {:ok, actualizado, _} = Recursos.entrada("R001", 50, recursos)

    assert actualizado.cantidad == 150
    assert hd(actualizado.historial).tipo == :entrada
  end

  test "registra una salida de recursos" do
    assert {:ok, _, recursos} = Recursos.registrar(@recurso, [])
    assert {:ok, actualizado, _} = Recursos.salida("R001", 30, recursos)

    assert actualizado.cantidad == 70
    assert hd(actualizado.historial).tipo == :salida
  end

  test "impide retirar más recursos de los disponibles" do
    assert {:ok, _, recursos} = Recursos.registrar(@recurso, [])

    assert {:error, _} = Recursos.salida("R001", 150, recursos)
  end

  test "registra transferencias y descuenta el inventario" do
    assert {:ok, _, recursos} = Recursos.registrar(@recurso, [])

    assert {:ok, actualizado, _} =
             Recursos.transferir("R001", 20, "Albergue Norte", recursos)

    assert actualizado.cantidad == 80
    assert hd(actualizado.historial).destino == "Albergue Norte"
  end

  test "busca y filtra recursos por categoría" do
    assert {:ok, _, recursos} = Recursos.registrar(@recurso, [])
    assert {:ok, encontrado} = Recursos.buscar("R001", recursos)

    assert encontrado.nombre == "Agua potable"

    assert length(Recursos.filtrar_por_categoria("Alimentos y bebidas", recursos)) == 1
  end
end
