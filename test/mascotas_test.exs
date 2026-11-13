defmodule SistemaEmergencias.MascotasTest do
  use ExUnit.Case

  alias SistemaEmergencias.Mascotas

  @perdida %{
    id: "MP001",
    tipo: :perdida,
    especie: "Perro",
    nombre: "Max",
    caracteristicas: "Mancha blanca en el pecho",
    color: "Cafe",
    tamano: "Mediano",
    zona: "Z001",
    contacto: "U001"
  }

  @encontrada %{
    id: "ME001",
    tipo: :encontrada,
    especie: "Perro",
    nombre: "Max",
    caracteristicas: "Mancha blanca en el pecho",
    color: "Cafe",
    tamano: "Mediano",
    zona: "Z001",
    contacto: "U002"
  }

  test "registra un reporte de mascota" do
    assert {:ok, reporte, [reporte]} = Mascotas.registrar(@perdida, [])
    assert reporte.estado == :activa
    assert reporte.tipo == :perdida
  end

  test "rechaza tipos de reporte inválidos" do
    assert {:error, _} =
             Mascotas.registrar(%{@perdida | tipo: :adopcion}, [])
  end

  test "no permite IDs repetidos" do
    assert {:ok, _, reportes} = Mascotas.registrar(@perdida, [])
    assert {:error, _} = Mascotas.registrar(@perdida, reportes)
  end

  test "calcula coincidencia entre reportes opuestos" do
    assert {:ok, _, reportes} = Mascotas.registrar(@perdida, [])
    assert {:ok, _, reportes} = Mascotas.registrar(@encontrada, reportes)

    assert {:ok, coincidencias} =
             Mascotas.posibles_coincidencias("MP001", reportes)

    assert length(coincidencias) == 1
    assert hd(coincidencias).puntaje == 100
  end

  test "no encuentra coincidencias con puntaje insuficiente" do
    diferente = %{@encontrada | id: "ME002", especie: "Gato", zona: "Z009"}

    assert {:ok, _, reportes} = Mascotas.registrar(@perdida, [])
    assert {:ok, _, reportes} = Mascotas.registrar(diferente, reportes)

    assert {:ok, []} = Mascotas.posibles_coincidencias("MP001", reportes)
  end

  test "confirma coincidencia y resuelve ambos reportes" do
    assert {:ok, _, reportes} = Mascotas.registrar(@perdida, [])
    assert {:ok, _, reportes} = Mascotas.registrar(@encontrada, reportes)

    assert {:ok, actualizados} =
             Mascotas.confirmar_coincidencia("MP001", "ME001", reportes)

    assert Enum.all?(actualizados, fn reporte ->
             reporte.estado == :resuelta
           end)
  end

  test "no permite confirmar dos reportes del mismo tipo" do
    otra = %{@perdida | id: "MP002"}

    assert {:ok, _, reportes} = Mascotas.registrar(@perdida, [])
    assert {:ok, _, reportes} = Mascotas.registrar(otra, reportes)

    assert {:error, _} =
             Mascotas.confirmar_coincidencia("MP001", "MP002", reportes)
  end

  test "busca un reporte por ID" do
    assert {:ok, _, reportes} = Mascotas.registrar(@perdida, [])
    assert {:ok, reporte} = Mascotas.buscar("MP001", reportes)
    assert reporte.nombre == "max"
  end
end
