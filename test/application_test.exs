defmodule SistemaEmergencias.ApplicationTest do
  use ExUnit.Case, async: false

  test "la aplicación inicia el supervisor y el servidor de inventario" do
    supervisor = Process.whereis(SistemaEmergencias.Supervisor)

    assert is_pid(supervisor)

    hijos = Supervisor.which_children(supervisor)

    assert Enum.any?(hijos, fn {modulo, _pid, _tipo, _modulos} ->
             modulo == SistemaEmergencias.InventarioServer
           end)
  end
end
