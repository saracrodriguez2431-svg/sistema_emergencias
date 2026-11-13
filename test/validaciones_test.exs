defmodule SistemaEmergencias.ValidacionesTest do
  use ExUnit.Case, async: true

  alias SistemaEmergencias.Validaciones

  test "acepta un texto obligatorio" do
    assert {:ok, "Armenia"} =
             Validaciones.texto_obligatorio("Armenia")
  end

  test "rechaza un texto vacio" do
    assert {:error, _mensaje} =
             Validaciones.texto_obligatorio("   ")
  end

  test "acepta un entero no negativo" do
    assert {:ok, 10} =
             Validaciones.entero_no_negativo(10)
  end

  test "rechaza un entero negativo" do
    assert {:error, _mensaje} =
             Validaciones.entero_no_negativo(-5)
  end

  test "acepta un numero decimal no negativo" do
    assert {:ok, 15.5} =
             Validaciones.numero_no_negativo(15.5)
  end

  test "rechaza un numero negativo" do
    assert {:error, _mensaje} =
             Validaciones.numero_no_negativo(-2.5)
  end

  test "acepta un identificador unico" do
    assert {:ok, "REC001"} =
             Validaciones.id_unico("REC001", ["REC002", "REC003"])
  end

  test "rechaza un identificador repetido" do
    assert {:error, _mensaje} =
             Validaciones.id_unico("REC001", ["REC001", "REC002"])
  end
end
