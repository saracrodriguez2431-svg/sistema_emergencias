defmodule SistemaEmergencias.MenuTest do
  use ExUnit.Case, async: true

  alias SistemaEmergencias.Menu

  test "genera el resumen de las colecciones" do
    resumen = %{
      usuarios: 2,
      zonas: 3,
      recursos: 5
    }

    texto = Menu.resumen_texto(resumen)

    assert texto =~ "usuarios: 2 registro(s)"
    assert texto =~ "zonas: 3 registro(s)"
    assert texto =~ "recursos: 5 registro(s)"
  end

  test "muestra un mensaje cuando una colección está vacía" do
    texto = Menu.coleccion_texto(:usuarios, [])

    assert texto =~ "usuarios"
    assert texto =~ "No hay registros almacenados."
  end

  test "representa los registros de una colección" do
    registros = [
      %{id: "U1", nombre: "Ciudadano"},
      %{id: "U2", nombre: "Voluntario"}
    ]

    texto = Menu.coleccion_texto(:usuarios, registros)

    assert texto =~ "Ciudadano"
    assert texto =~ "Voluntario"
    assert texto =~ "1."
    assert texto =~ "2."
  end
end
