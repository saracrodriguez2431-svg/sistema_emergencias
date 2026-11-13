defmodule SistemaEmergencias.NecesidadesTest do
  use ExUnit.Case

  alias SistemaEmergencias.Necesidades

  @necesidad %{
    id: "N001",
    tipo: "Agua",
    descripcion: "Agua potable para familias afectadas",
    cantidad: 100,
    zona: "Z001",
    prioridad: "critica",
    responsable: nil
  }

  test "registra una necesidad correctamente" do
    assert {:ok, necesidad, [necesidad]} =
             Necesidades.registrar(@necesidad, [])

    assert necesidad.estado == :pendiente
    assert necesidad.cantidad == 100
    assert necesidad.prioridad == :critica
  end

  test "rechaza cantidades iguales a cero o negativas" do
    assert {:error, _} =
             Necesidades.registrar(%{@necesidad | cantidad: 0}, [])

    assert {:error, _} =
             Necesidades.registrar(%{@necesidad | cantidad: -5}, [])
  end

  test "rechaza prioridades inválidas" do
    assert {:error, _} =
             Necesidades.registrar(%{@necesidad | prioridad: "urgente"}, [])
  end

  test "no permite IDs repetidos" do
    assert {:ok, _, necesidades} =
             Necesidades.registrar(@necesidad, [])

    assert {:error, _} =
             Necesidades.registrar(@necesidad, necesidades)
  end

  test "asigna un responsable a una necesidad" do
    assert {:ok, _, necesidades} =
             Necesidades.registrar(@necesidad, [])

    assert {:ok, actualizada, _} =
             Necesidades.asignar("N001", "Carlos", necesidades)

    assert actualizada.responsable == "Carlos"
    assert actualizada.estado == :asignada
  end

  test "permite cambiar estados siguiendo las transiciones" do
    assert {:ok, _, necesidades} =
             Necesidades.registrar(@necesidad, [])

    assert {:ok, _, necesidades} =
             Necesidades.asignar("N001", "Carlos", necesidades)

    assert {:ok, actualizada, necesidades} =
             Necesidades.cambiar_estado("N001", :en_atencion, necesidades)

    assert actualizada.estado == :en_atencion

    assert {:ok, atendida, _} =
             Necesidades.cambiar_estado("N001", :atendida, necesidades)

    assert atendida.estado == :atendida
  end

  test "no permite cerrar dos veces una necesidad atendida" do
    assert {:ok, _, necesidades} =
             Necesidades.registrar(@necesidad, [])

    assert {:ok, _, necesidades} =
             Necesidades.asignar("N001", "Carlos", necesidades)

    assert {:ok, _, necesidades} =
             Necesidades.cambiar_estado("N001", :en_atencion, necesidades)

    assert {:ok, _, necesidades} =
             Necesidades.cambiar_estado("N001", :atendida, necesidades)

    assert {:error, _} =
             Necesidades.cambiar_estado("N001", :cancelada, necesidades)
  end

  test "ordena las necesidades por prioridad" do
    urgente = %{@necesidad | id: "N002", prioridad: "alta"}
    baja = %{@necesidad | id: "N003", prioridad: "baja"}

    assert {:ok, _, lista} = Necesidades.registrar(baja, [])
    assert {:ok, _, lista} = Necesidades.registrar(urgente, lista)
    assert {:ok, _, lista} = Necesidades.registrar(@necesidad, lista)

    ordenadas = Necesidades.ordenar_por_prioridad(lista)

    assert Enum.map(ordenadas, & &1.prioridad) ==
             [:critica, :alta, :baja]
  end

  test "filtra necesidades por zona" do
    otra = %{@necesidad | id: "N002", zona: "Z002"}

    assert {:ok, _, lista} = Necesidades.registrar(@necesidad, [])
    assert {:ok, _, lista} = Necesidades.registrar(otra, lista)

    resultado = Necesidades.filtrar_por_zona("Z001", lista)

    assert length(resultado) == 1
    assert hd(resultado).id == "N001"
  end
end
