defmodule SistemaEmergencias.Usuarios do
  alias SistemaEmergencias.Validaciones
  @roles [:ciudadano, :voluntario, :coordinador, :administrador]

  def registrar(usuario, usuarios) when is_map(usuario) and is_list(usuarios) do
    id = Map.get(usuario, :id)
    nombre = Map.get(usuario, :nombre)
    correo = Map.get(usuario, :correo)
    clave = Map.get(usuario, :clave)
    rol = Map.get(usuario, :rol)

    with {:ok, id} <- Validaciones.texto_obligatorio(id),
         {:ok, nombre} <- Validaciones.texto_obligatorio(nombre),
         {:ok, correo} <- Validaciones.texto_obligatorio(correo),
         {:ok, clave} <- Validaciones.texto_obligatorio(clave),
         :ok <- validar_rol(rol),
         :ok <- validar_clave(clave),
         :ok <- validar_id_unico(id, usuarios),
         :ok <- validar_correo_unico(correo, usuarios) do
      nuevo_usuario = %{
        id: id,
        nombre: nombre,
        correo: String.downcase(correo),
        clave_hash: hash_clave(clave),
        rol: normalizar_rol(rol),
        conectado: false
      }

      {:ok, nuevo_usuario, [nuevo_usuario | usuarios]}
    else
      {:error, motivo} -> {:error, motivo}
    end
  end

  def registrar(_, _), do: {:error, "Los datos del usuario no son válidos"}

  def buscar(id, usuarios) when is_list(usuarios) do
    case Enum.find(usuarios, fn usuario -> usuario.id == id end) do
      nil -> {:error, "No se encontró el usuario"}
      usuario -> {:ok, usuario}
    end
  end

  def listar(usuarios) when is_list(usuarios), do: usuarios

  def iniciar_sesion(id, clave, usuarios) when is_list(usuarios) do
    with {:ok, usuario} <- buscar(id, usuarios),
         true <- hash_clave(clave) == usuario.clave_hash do
      usuario_actualizado = %{usuario | conectado: true}

      usuarios_actualizados =
        Enum.map(usuarios, fn elemento ->
          if elemento.id == id, do: usuario_actualizado, else: elemento
        end)

      {:ok, usuario_actualizado, usuarios_actualizados}
    else
      false -> {:error, "La contraseña es incorrecta"}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def cerrar_sesion(id, usuarios) when is_list(usuarios) do
    with {:ok, usuario} <- buscar(id, usuarios),
         true <- usuario.conectado do
      usuario_actualizado = %{usuario | conectado: false}

      usuarios_actualizados =
        Enum.map(usuarios, fn elemento ->
          if elemento.id == id, do: usuario_actualizado, else: elemento
        end)

      {:ok, usuario_actualizado, usuarios_actualizados}
    else
      false -> {:error, "El usuario no tiene una sesión activa"}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def validar_rol(rol) do
    if normalizar_rol(rol) in @roles do
      :ok
    else
      {:error, "El rol indicado no es válido"}
    end
  end

  defp validar_clave(clave) do
    if String.length(clave) >= 6 do
      :ok
    else
      {:error, "La contraseña debe tener al menos 6 caracteres"}
    end
  end

  defp validar_id_unico(id, usuarios) do
    if Enum.any?(usuarios, fn usuario -> usuario.id == id end) do
      {:error, "Ya existe un usuario con ese ID"}
    else
      :ok
    end
  end

  defp validar_correo_unico(correo, usuarios) do
    existe =
      Enum.any?(usuarios, fn usuario ->
        String.downcase(usuario.correo) == String.downcase(correo)
      end)

    if existe do
      {:error, "Ya existe un usuario con ese correo"}
    else
      :ok
    end
  end

  defp normalizar_rol(rol) when is_atom(rol), do: rol

  defp normalizar_rol(rol) when is_binary(rol) do
    case String.downcase(String.trim(rol)) do
      "ciudadano" -> :ciudadano
      "voluntario" -> :voluntario
      "coordinador" -> :coordinador
      "administrador" -> :administrador
      _ -> :desconocido
    end
  end

  defp normalizar_rol(_), do: :desconocido

  defp hash_clave(clave) do
    :crypto.hash(:sha256, clave)
    |> Base.encode16(case: :lower)
  end
end
