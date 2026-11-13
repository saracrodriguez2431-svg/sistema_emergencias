defmodule SistemaEmergencias.Recursos do
  def registrar(recurso, recursos) when is_map(recurso) and is_list(recursos) do
    codigo = Map.get(recurso, :codigo)
    nombre = Map.get(recurso, :nombre)
    categoria = Map.get(recurso, :categoria)
    cantidad = Map.get(recurso, :cantidad)
    unidad = Map.get(recurso, :unidad)
    ubicacion = Map.get(recurso, :ubicacion)

    with {:ok, codigo} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(codigo),
         {:ok, nombre} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(nombre),
         {:ok, categoria} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(categoria),
         {:ok, unidad} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(unidad),
         {:ok, ubicacion} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(ubicacion),
         :ok <- validar_cantidad(cantidad),
         :ok <- validar_codigo_unico(codigo, recursos) do
      nuevo = %{
        codigo: codigo,
        nombre: nombre,
        categoria: categoria,
        cantidad: cantidad,
        unidad: unidad,
        ubicacion: ubicacion,
        historial: [
          %{tipo: :registro, cantidad: cantidad, ubicacion: ubicacion}
        ]
      }

      {:ok, nuevo, [nuevo | recursos]}
    end
  end

  def registrar(_, _), do: {:error, "Los datos del recurso no son válidos"}

  def buscar(codigo, recursos) when is_list(recursos) do
    case Enum.find(recursos, fn recurso -> recurso.codigo == codigo end) do
      nil -> {:error, "No se encontró el recurso"}
      recurso -> {:ok, recurso}
    end
  end

  def listar(recursos) when is_list(recursos), do: recursos

  def entrada(codigo, cantidad, recursos) when is_list(recursos) do
    with :ok <- validar_cantidad(cantidad),
         {:ok, recurso} <- buscar(codigo, recursos) do
      actualizar_recurso(
        recurso,
        %{
          cantidad: recurso.cantidad + cantidad,
          historial: agregar_movimiento(recurso, :entrada, cantidad)
        },
        recursos
      )
    end
  end

  def salida(codigo, cantidad, recursos) when is_list(recursos) do
    with :ok <- validar_cantidad(cantidad),
         {:ok, recurso} <- buscar(codigo, recursos),
         :ok <- validar_existencia(recurso.cantidad, cantidad) do
      actualizar_recurso(
        recurso,
        %{
          cantidad: recurso.cantidad - cantidad,
          historial: agregar_movimiento(recurso, :salida, cantidad)
        },
        recursos
      )
    end
  end

  def transferir(codigo, cantidad, destino, recursos) when is_list(recursos) do
    with :ok <- validar_cantidad(cantidad),
         {:ok, destino} <-
           SistemaEmergencias.Validaciones.texto_obligatorio(destino),
         {:ok, recurso} <- buscar(codigo, recursos),
         :ok <- validar_existencia(recurso.cantidad, cantidad) do
      movimiento = %{
        tipo: :transferencia,
        cantidad: cantidad,
        origen: recurso.ubicacion,
        destino: destino
      }

      actualizar_recurso(
        recurso,
        %{
          cantidad: recurso.cantidad - cantidad,
          historial: [movimiento | recurso.historial]
        },
        recursos
      )
    end
  end

  def filtrar_por_categoria(categoria, recursos) when is_list(recursos) do
    Enum.filter(recursos, fn recurso ->
      String.downcase(recurso.categoria) == String.downcase(categoria)
    end)
  end

  defp actualizar_recurso(recurso, cambios, recursos) do
    actualizado = Map.merge(recurso, cambios)

    lista_actualizada =
      Enum.map(recursos, fn elemento ->
        if elemento.codigo == recurso.codigo, do: actualizado, else: elemento
      end)

    {:ok, actualizado, lista_actualizada}
  end

  defp agregar_movimiento(recurso, tipo, cantidad) do
    movimiento = %{
      tipo: tipo,
      cantidad: cantidad,
      ubicacion: recurso.ubicacion
    }

    [movimiento | recurso.historial]
  end

  defp validar_cantidad(cantidad) when is_integer(cantidad) and cantidad > 0,
    do: :ok

  defp validar_cantidad(_),
    do: {:error, "La cantidad debe ser un entero mayor que cero"}

  defp validar_codigo_unico(codigo, recursos) do
    if Enum.any?(recursos, fn recurso -> recurso.codigo == codigo end) do
      {:error, "Ya existe un recurso con ese código"}
    else
      :ok
    end
  end

  defp validar_existencia(disponible, solicitado) do
    if solicitado <= disponible do
      :ok
    else
      {:error, "No hay suficiente inventario disponible"}
    end
  end
end
