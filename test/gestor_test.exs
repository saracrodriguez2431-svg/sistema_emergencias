defmodule SistemaEmergencias.GestorTest do
  use ExUnit.Case, async: true

  alias SistemaEmergencias.Gestor

  test "crea el estado inicial con las ocho colecciones" do
    estado = Gestor.estado_inicial()

    assert map_size(estado) == 8
    assert estado.usuarios == []
    assert estado.zonas == []
    assert estado.recursos == []
    assert estado.albergues == []
  end

  test "genera un resumen de las colecciones" do
    estado =
      Gestor.estado_inicial()
      |> Map.put(:usuarios, [%{id: "U1"}, %{id: "U2"}])
      |> Map.put(:recursos, [%{codigo: "R1"}])
      |> Map.put(:mascotas, [%{id: "M1"}, %{id: "M2"}, %{id: "M3"}])

    resumen = Gestor.resumen(estado)

    assert resumen.usuarios == 2
    assert resumen.recursos == 1
    assert resumen.mascotas == 3
    assert resumen.albergues == 0
  end

  test "inicia el sistema recuperando las colecciones" do
    assert {:ok, estado} = Gestor.iniciar()

    assert is_list(estado.usuarios)
    assert is_list(estado.zonas)
    assert is_list(estado.recursos)
    assert is_list(estado.albergues)
  end

  test "rechaza estados que no sean mapas al guardar" do
    assert {:error, _} = Gestor.guardar([])
  end
end
