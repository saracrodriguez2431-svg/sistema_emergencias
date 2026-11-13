defmodule SistemaEmergencias.PersistenciaTest do
  use ExUnit.Case, async: true

  alias SistemaEmergencias.Persistencia

  test "guarda y recupera información" do
    directorio =
      Path.join(System.tmp_dir!(), "emergencias_test_#{System.unique_integer([:positive])}")

    datos = [%{id: "R1", nombre: "Agua", cantidad: 20}]

    assert {:ok, _} = Persistencia.guardar_en(directorio, :recursos, datos)
    assert {:ok, ^datos} = Persistencia.cargar_desde(directorio, :recursos)

    File.rm_rf!(directorio)
  end

  test "devuelve una lista vacía si el archivo no existe" do
    directorio =
      Path.join(System.tmp_dir!(), "emergencias_vacio_#{System.unique_integer([:positive])}")

    assert {:ok, []} = Persistencia.cargar_desde(directorio, :usuarios)
  end

  test "rechaza nombres de archivo no permitidos" do
    assert {:error, _} = Persistencia.guardar(:archivo_desconocido, [])
    assert {:error, _} = Persistencia.cargar(:archivo_desconocido)
  end
end
