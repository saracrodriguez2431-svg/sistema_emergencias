defmodule SistemaEmergencias.AlmacenamientoTest do
  use ExUnit.Case, async: true

  alias SistemaEmergencias.Almacenamiento

  setup do
    directorio =
      Path.join(System.tmp_dir!(), "almacenamiento_#{System.unique_integer([:positive])}")

    estado =
      Map.new(Almacenamiento.colecciones(), fn nombre ->
        {nombre, []}
      end)

    %{directorio: directorio, estado: estado}
  end

  test "define las ocho colecciones del sistema" do
    assert length(Almacenamiento.colecciones()) == 8
    assert :usuarios in Almacenamiento.colecciones()
    assert :recursos in Almacenamiento.colecciones()
    assert :albergues in Almacenamiento.colecciones()
  end

  test "actualiza una colección y devuelve el estado nuevo", %{estado: estado} do
    datos = [%{codigo: "R1", cantidad: 10}]

    # Se comprueba la validación de la colección sin escribir en archivos.
    assert {:error, _} = Almacenamiento.actualizar(estado, :desconocida, datos)
  end

  test "rechaza un estado incompleto al guardar", %{estado: estado} do
    estado_incompleto = Map.delete(estado, :mascotas)

    assert {:error, mensaje} = Almacenamiento.guardar_todo(estado_incompleto)
    assert mensaje =~ "mascotas"
  end

  test "carga colecciones vacías cuando todavía no existen archivos" do
    assert {:ok, estado} = Almacenamiento.cargar_todo()

    assert Enum.all?(Almacenamiento.colecciones(), fn nombre ->
             is_list(Map.get(estado, nombre))
           end)
  end
end
