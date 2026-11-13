defmodule SistemaEmergencias.ZonasTest do
  use ExUnit.Case

  alias SistemaEmergencias.Zonas

  @zona %{
    id: "Z001",
    nombre: "Zona Norte",
    nivel: "critico"
  }

  @sector %{
    id: "S001",
    nombre: "Sector Central"
  }

  @punto %{
    id: "P001",
    nombre: "Puesto de atención principal",
    direccion: "Calle 10"
  }

  test "registra una zona correctamente" do
    assert {:ok, zona, [zona]} = Zonas.registrar_zona(@zona, [])
    assert zona.id == "Z001"
    assert zona.nivel == :critico
    assert zona.sectores == []
  end

  test "rechaza una zona con nivel inválido" do
    zona = %{@zona | nivel: "extremo"}
    assert {:error, _} = Zonas.registrar_zona(zona, [])
  end

  test "no permite zonas con ID repetido" do
    assert {:ok, _, zonas} = Zonas.registrar_zona(@zona, [])
    assert {:error, _} = Zonas.registrar_zona(@zona, zonas)
  end

  test "agrega un sector a una zona" do
    assert {:ok, _, zonas} = Zonas.registrar_zona(@zona, [])
    assert {:ok, sector, zonas} = Zonas.agregar_sector("Z001", @sector, zonas)
    assert sector.id == "S001"
    assert {:ok, zona} = Zonas.buscar_zona("Z001", zonas)
    assert length(zona.sectores) == 1
  end

  test "agrega un punto de atención a un sector" do
    assert {:ok, _, zonas} = Zonas.registrar_zona(@zona, [])
    assert {:ok, _, zonas} = Zonas.agregar_sector("Z001", @sector, zonas)

    assert {:ok, punto, zonas} =
             Zonas.agregar_punto("Z001", "S001", @punto, zonas)

    assert punto.id == "P001"
    assert Zonas.contar_puntos(zonas) == 1
  end

  test "no permite puntos de atención con ID repetido" do
    assert {:ok, _, zonas} = Zonas.registrar_zona(@zona, [])
    assert {:ok, _, zonas} = Zonas.agregar_sector("Z001", @sector, zonas)
    assert {:ok, _, zonas} = Zonas.agregar_punto("Z001", "S001", @punto, zonas)

    assert {:error, _} =
             Zonas.agregar_punto("Z001", "S001", @punto, zonas)
  end

  test "cuenta sectores y lista puntos de todas las zonas" do
    assert {:ok, _, zonas} = Zonas.registrar_zona(@zona, [])
    assert {:ok, _, zonas} = Zonas.agregar_sector("Z001", @sector, zonas)
    assert {:ok, _, zonas} = Zonas.agregar_punto("Z001", "S001", @punto, zonas)

    assert Zonas.contar_sectores(zonas) == 1
    assert length(Zonas.listar_puntos(zonas)) == 1
  end

  test "devuelve error al buscar una zona inexistente" do
    assert {:error, _} = Zonas.buscar_zona("Z999", [])
  end
end
