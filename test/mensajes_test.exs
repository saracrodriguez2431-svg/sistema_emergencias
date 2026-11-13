defmodule SistemaEmergencias.MensajesTest do
  use ExUnit.Case

  alias SistemaEmergencias.Mensajes

  @mensaje %{
    id: "M001",
    remitente: "U001",
    destinatario: "U002",
    contenido: "Estoy buscando a mi familiar"
  }

  test "envía un mensaje correctamente" do
    assert {:ok, mensaje, [mensaje]} = Mensajes.enviar(@mensaje, [])

    assert mensaje.estado == :enviado
    assert mensaje.remitente == "U001"
    assert mensaje.destinatario == "U002"
    assert %DateTime{} = mensaje.fecha
  end

  test "no permite IDs repetidos" do
    assert {:ok, _, mensajes} = Mensajes.enviar(@mensaje, [])
    assert {:error, _} = Mensajes.enviar(@mensaje, mensajes)
  end

  test "rechaza contenido vacío" do
    assert {:error, _} =
             Mensajes.enviar(%{@mensaje | contenido: " "}, [])
  end

  test "busca mensajes por ID" do
    assert {:ok, _, mensajes} = Mensajes.enviar(@mensaje, [])
    assert {:ok, encontrado} = Mensajes.buscar("M001", mensajes)

    assert encontrado.contenido == "Estoy buscando a mi familiar"
  end

  test "consulta historial y mensajes recibidos" do
    assert {:ok, _, mensajes} = Mensajes.enviar(@mensaje, [])

    assert length(Mensajes.historial_usuario("U001", mensajes)) == 1
    assert length(Mensajes.recibidos("U002", mensajes)) == 1
    assert Mensajes.recibidos("U001", mensajes) == []
  end

  test "actualiza el estado del mensaje" do
    assert {:ok, _, mensajes} = Mensajes.enviar(@mensaje, [])

    assert {:ok, entregado, mensajes} =
             Mensajes.actualizar_estado("M001", :entregado, mensajes)

    assert entregado.estado == :entregado

    assert {:ok, leido, _} =
             Mensajes.actualizar_estado("M001", :leido, mensajes)

    assert leido.estado == :leido
  end

  test "no permite transiciones inválidas" do
    assert {:ok, _, mensajes} = Mensajes.enviar(@mensaje, [])

    assert {:error, _} =
             Mensajes.actualizar_estado("M001", :leido, mensajes)
  end

  test "no permite actualizar un mensaje inexistente" do
    assert {:error, _} = Mensajes.actualizar_estado("M999", :entregado, [])
  end
end
