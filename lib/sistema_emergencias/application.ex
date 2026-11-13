defmodule SistemaEmergencias.Application do
  use Application

  @impl true
  def start(_tipo, _argumentos) do
    hijos = [
      {SistemaEmergencias.InventarioServer, []}
    ]

    opciones = [
      strategy: :one_for_one,
      name: SistemaEmergencias.Supervisor
    ]

    Supervisor.start_link(hijos, opciones)
  end
end
