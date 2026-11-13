defmodule SistemaEmergencias.PersonasTest do
  use ExUnit.Case

  alias SistemaEmergencias.Personas

  @persona %{
    id: "P001",
    nombre: "Laura Gomez",
    documento: "10940001",
    edad: 25,
    zona: "Z001",
    estado: :sin_confirmar
  }

  test "registra una persona correctamente" do
    assert {:ok, persona, [persona]} = Personas.registrar(@persona, [])
    assert persona.nombre == "Laura Gomez"
    assert persona.estado == :sin_confirmar
    assert length(persona.historial) == 1
  end

  test "rechaza edades negativas" do
    assert {:error, _} =
             Personas.registrar(%{@persona | edad: -1}, [])
  end

  test "no permite IDs repetidos" do
    assert {:ok, _, personas} = Personas.registrar(@persona, [])
    assert {:error, _} = Personas.registrar(@persona, personas)
  end

  test "no permite documentos repetidos" do
    assert {:ok, _, personas} = Personas.registrar(@persona, [])
    otra = %{@persona | id: "P002"}

    assert {:error, _} = Personas.registrar(otra, personas)
  end

  test "busca por ID y por documento" do
    assert {:ok, _, personas} = Personas.registrar(@persona, [])

    assert {:ok, persona} = Personas.buscar("P001", personas)
    assert persona.nombre == "Laura Gomez"

    assert {:ok, persona} =
             Personas.buscar_por_documento("10940001", personas)

    assert persona.id == "P001"
  end

  test "actualiza el estado y conserva el historial" do
    assert {:ok, _, personas} = Personas.registrar(@persona, [])

    assert {:ok, actualizada, _personas} =
             Personas.actualizar_estado("P001", :localizada, personas)

    assert actualizada.estado == :localizada
    assert length(actualizada.historial) == 2
  end

  test "rechaza estados inválidos" do
    assert {:ok, _, personas} = Personas.registrar(@persona, [])

    assert {:error, _} =
             Personas.actualizar_estado("P001", :desconocido, personas)
  end

  test "filtra personas por zona y estado" do
    assert {:ok, _, personas} = Personas.registrar(@persona, [])

    assert length(Personas.filtrar_por_zona("Z001", personas)) == 1
    assert length(Personas.filtrar_por_estado(:sin_confirmar, personas)) == 1
  end
end
