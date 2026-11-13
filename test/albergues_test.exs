defmodule SistemaEmergencias.AlberguesTest do
  use ExUnit.Case

  alias SistemaEmergencias.Albergues

  @albergue %{
    id: "A001",
    nombre: "Albergue Central",
    zona: "Z001",
    capacidad: 100
  }

  test "registra un albergue correctamente" do
    assert {:ok, albergue, [albergue]} = Albergues.registrar(@albergue, [])

    assert albergue.ocupacion == 0
    assert albergue.capacidad == 100
  end

  test "rechaza capacidades inválidas" do
    assert {:error, _} =
             Albergues.registrar(%{@albergue | capacidad: 0}, [])

    assert {:error, _} =
             Albergues.registrar(%{@albergue | capacidad: -5}, [])
  end

  test "no permite IDs repetidos" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])
    assert {:error, _} = Albergues.registrar(@albergue, albergues)
  end

  test "registra ingreso de personas" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])

    assert {:ok, actualizado, _} =
             Albergues.ingresar_personas("A001", 30, albergues)

    assert actualizado.ocupacion == 30
  end

  test "impide superar la capacidad" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])

    assert {:error, _} =
             Albergues.ingresar_personas("A001", 101, albergues)
  end

  test "registra salida de personas" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])

    assert {:ok, _, albergues} =
             Albergues.ingresar_personas("A001", 30, albergues)

    assert {:ok, actualizado, _} =
             Albergues.retirar_personas("A001", 10, albergues)

    assert actualizado.ocupacion == 20
  end

  test "impide retirar más personas de las alojadas" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])

    assert {:error, _} =
             Albergues.retirar_personas("A001", 5, albergues)
  end

  test "asocia recursos y necesidades" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])

    assert {:ok, _actualizado, albergues} =
             Albergues.asociar_recurso("A001", "R001", albergues)

    assert {:ok, actualizado, _} =
             Albergues.asociar_necesidad("A001", "N001", albergues)

    assert "R001" in actualizado.recursos
    assert "N001" in actualizado.necesidades
  end

  test "calcula porcentaje y encuentra mayor ocupación" do
    assert {:ok, _, albergues} = Albergues.registrar(@albergue, [])

    assert {:ok, _, albergues} =
             Albergues.ingresar_personas("A001", 50, albergues)

    assert {:ok, mayor} = Albergues.mayor_ocupacion(albergues)
    assert mayor.id == "A001"
    assert Albergues.porcentaje_ocupacion(mayor) == 50.0
  end
end
