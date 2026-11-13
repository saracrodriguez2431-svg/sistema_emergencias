defmodule SistemaEmergencias.UsuariosTest do
  use ExUnit.Case

  alias SistemaEmergencias.Usuarios

  @usuario %{
    id: "U001",
    nombre: "Ana Perez",
    correo: "ana@correo.com",
    clave: "clave123",
    rol: "ciudadano"
  }

  test "registra un usuario correctamente" do
    assert {:ok, usuario, [usuario]} = Usuarios.registrar(@usuario, [])
    assert usuario.id == "U001"
    assert usuario.rol == :ciudadano
    assert usuario.conectado == false
    refute Map.has_key?(usuario, :clave)
  end

  test "no permite registrar dos usuarios con el mismo ID" do
    assert {:ok, _, usuarios} = Usuarios.registrar(@usuario, [])
    assert {:error, _} = Usuarios.registrar(@usuario, usuarios)
  end

  test "no permite registrar dos usuarios con el mismo correo" do
    assert {:ok, _, usuarios} = Usuarios.registrar(@usuario, [])

    otro = %{@usuario | id: "U002"}

    assert {:error, _} = Usuarios.registrar(otro, usuarios)
  end

  test "rechaza contraseñas demasiado cortas" do
    usuario = %{@usuario | clave: "123"}

    assert {:error, _} = Usuarios.registrar(usuario, [])
  end

  test "rechaza roles que no existen" do
    usuario = %{@usuario | rol: "superusuario"}

    assert {:error, _} = Usuarios.registrar(usuario, [])
  end

  test "busca un usuario por su ID" do
    assert {:ok, usuario, usuarios} = Usuarios.registrar(@usuario, [])
    assert {:ok, encontrado} = Usuarios.buscar("U001", usuarios)
    assert encontrado.id == usuario.id
  end

  test "inicia y cierra sesión" do
    assert {:ok, _, usuarios} = Usuarios.registrar(@usuario, [])

    assert {:ok, conectado, usuarios} =
             Usuarios.iniciar_sesion("U001", "clave123", usuarios)

    assert conectado.conectado == true

    assert {:ok, desconectado, _usuarios} =
             Usuarios.cerrar_sesion("U001", usuarios)

    assert desconectado.conectado == false
  end

  test "rechaza una contraseña incorrecta" do
    assert {:ok, _, usuarios} = Usuarios.registrar(@usuario, [])

    assert {:error, _} =
             Usuarios.iniciar_sesion("U001", "incorrecta", usuarios)
  end
end
