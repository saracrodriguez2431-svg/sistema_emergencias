defmodule SistemaEmergencias.Menu do
  alias SistemaEmergencias.Gestor
  alias SistemaEmergencias.Almacenamiento
  alias SistemaEmergencias.Necesidades
  alias SistemaEmergencias.Recursos
  alias SistemaEmergencias.Personas
  alias SistemaEmergencias.Mensajes
  alias SistemaEmergencias.Mascotas
  alias SistemaEmergencias.Albergues
  alias Util2

  @doc "Inicia el sistema y carga la información almacenada."
  def iniciar do
    case Gestor.iniciar() do
      {:ok, estado} ->
        Util2.mostrar("========================================", :mensaje)
        Util2.mostrar(" SISTEMA DE COORDINACIÓN DE EMERGENCIAS", :mensaje)
        Util2.mostrar("========================================", :mensaje)
        mostrar_menu(estado)

      {:error, razon} ->
        Util2.mostrar("No fue posible iniciar el sistema: #{razon}", :error)
    end
  end

  defp mostrar_menu(estado) do
    Util2.mostrar("\n========== MENÚ PRINCIPAL ==========", :mensaje)
    Util2.mostrar("1. Consultar resumen general", :mensaje)
    Util2.mostrar("2. Consultar registros de una sección", :mensaje)
    Util2.mostrar("3. Guardar toda la información", :mensaje)
    Util2.mostrar("4. Gestionar necesidades", :mensaje)
    Util2.mostrar("5. Salir", :mensaje)
    Util2.mostrar("6. Gestionar recursos e inventario", :mensaje)
    Util2.mostrar("7. Gestionar personas afectadas", :mensaje)
    Util2.mostrar("8. Gestionar comunicación familiar", :mensaje)
    Util2.mostrar("9. Gestionar mascotas perdidas y encontradas", :mensaje)
    Util2.mostrar("10. Gestionar albergues", :mensaje)

    opcion = Util2.ingresar("Seleccione una opción: ", :entero)

    case opcion do
      1 ->
        mostrar_resumen(estado)
        mostrar_menu(estado)

      2 ->
        mostrar_seleccion_coleccion(estado)
        mostrar_menu(estado)

      3 ->
        guardar_informacion(estado)
        mostrar_menu(estado)

      4 ->
        nuevo_estado = gestionar_necesidades(estado)
        mostrar_menu(nuevo_estado)

      5 ->
        Util2.mostrar("Cerrando el sistema. ¡Hasta pronto!", :mensaje)

      6 ->
        nuevo_estado = gestionar_recursos(estado)
        mostrar_menu(nuevo_estado)

      7 ->
        nuevo_estado = gestionar_personas(estado)
        mostrar_menu(nuevo_estado)

      8 ->
        nuevo_estado = gestionar_mensajes(estado)
        mostrar_menu(nuevo_estado)

      9 ->
        nuevo_estado = gestionar_mascotas(estado)
        mostrar_menu(nuevo_estado)

      10 ->
        nuevo_estado = gestionar_albergues(estado)
        mostrar_menu(nuevo_estado)

      _ ->
        Util2.mostrar("Opción no válida. Intente nuevamente.", :error)
        mostrar_menu(estado)
    end
  end

  defp mostrar_resumen(estado) do
    resumen = Gestor.resumen(estado)

    Util2.mostrar("\n========== RESUMEN GENERAL ==========", :mensaje)
    Util2.mostrar(resumen_texto(resumen), :mensaje)
  end

  defp mostrar_seleccion_coleccion(estado) do
    colecciones = Almacenamiento.colecciones()

    Util2.mostrar("\nSeleccione una sección:", :mensaje)

    colecciones
    |> Enum.with_index(1)
    |> Enum.each(fn {nombre, numero} ->
      Util2.mostrar("#{numero}. #{nombre}", :mensaje)
    end)

    opcion = Util2.ingresar("Número de sección: ", :entero)

    if is_integer(opcion) and opcion >= 1 and opcion <= length(colecciones) do
      nombre = Enum.at(colecciones, opcion - 1)
      registros = Map.get(estado, nombre, [])
      Util2.mostrar(coleccion_texto(nombre, registros), :mensaje)
    else
      Util2.mostrar("Sección no válida.", :error)
    end
  end

  # SUBMENÚ DE NECESIDADES

  defp gestionar_necesidades(estado) do
    Util2.mostrar("\n========== GESTIÓN DE NECESIDADES ==========", :mensaje)
    Util2.mostrar("1. Consultar necesidades", :mensaje)
    Util2.mostrar("2. Registrar una necesidad", :mensaje)
    Util2.mostrar("3. Asignar responsable", :mensaje)
    Util2.mostrar("4. Cambiar estado de una necesidad", :mensaje)
    Util2.mostrar("5. Ordenar por prioridad", :mensaje)
    Util2.mostrar("6. Volver al menú principal", :mensaje)

    opcion = Util2.ingresar("Seleccione una opción: ", :entero)

    case opcion do
      1 ->
        mostrar_necesidades(estado)
        gestionar_necesidades(estado)

      2 ->
        nuevo_estado = registrar_necesidad(estado)
        gestionar_necesidades(nuevo_estado)

      3 ->
        nuevo_estado = asignar_responsable(estado)
        gestionar_necesidades(nuevo_estado)

      4 ->
        nuevo_estado = cambiar_estado_necesidad(estado)
        gestionar_necesidades(nuevo_estado)

      5 ->
        ordenar_necesidades(estado)
        gestionar_necesidades(estado)

      6 ->
        Util2.mostrar("Regresando al menú principal.", :mensaje)
        estado

      _ ->
        Util2.mostrar("Opción no válida.", :error)
        gestionar_necesidades(estado)
    end
  end

  defp mostrar_necesidades(estado) do
    registros = Map.get(estado, :necesidades, [])

    Util2.mostrar(
      coleccion_texto(:necesidades, registros),
      :mensaje
    )
  end

  defp registrar_necesidad(estado) do
    Util2.mostrar("\n========== REGISTRAR NECESIDAD ==========", :mensaje)

    id = Util2.ingresar("ID de la necesidad: ", :texto)
    tipo = Util2.ingresar("Tipo de necesidad: ", :texto)
    descripcion = Util2.ingresar("Descripción: ", :texto)
    cantidad = Util2.ingresar("Cantidad solicitada: ", :entero)
    zona = Util2.ingresar("Zona donde se requiere: ", :texto)

    prioridad =
      Util2.ingresar(
        "Prioridad (critica, alta, media, baja): ",
        :texto
      )

    responsable =
      Util2.ingresar(
        "Responsable (deje vacío si no tiene): ",
        :texto
      )

    responsable =
      if String.trim(responsable) == "" do
        nil
      else
        responsable
      end

    datos = %{
      id: id,
      tipo: tipo,
      descripcion: descripcion,
      cantidad: cantidad,
      zona: zona,
      prioridad: prioridad,
      responsable: responsable
    }

    case Necesidades.registrar(datos, Map.get(estado, :necesidades, [])) do
      {:ok, necesidad, lista_actualizada} ->
        Util2.mostrar(
          "Necesidad #{necesidad.id} registrada correctamente.",
          :mensaje
        )

        guardar_cambio_necesidades(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible registrar: #{razon}", :error)
        estado
    end
  end

  defp asignar_responsable(estado) do
    Util2.mostrar("\n========== ASIGNAR RESPONSABLE ==========", :mensaje)

    id = Util2.ingresar("ID de la necesidad: ", :texto)
    responsable = Util2.ingresar("Nombre del responsable: ", :texto)

    case Necesidades.asignar(
           id,
           responsable,
           Map.get(estado, :necesidades, [])
         ) do
      {:ok, necesidad, lista_actualizada} ->
        Util2.mostrar(
          "Responsable asignado correctamente a #{necesidad.id}.",
          :mensaje
        )

        guardar_cambio_necesidades(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible asignar: #{razon}", :error)
        estado
    end
  end

  defp cambiar_estado_necesidad(estado) do
    Util2.mostrar("\n========== CAMBIAR ESTADO ==========", :mensaje)
    Util2.mostrar("Estados disponibles:", :mensaje)
    Util2.mostrar("pendiente, asignada, en_atencion, atendida, cancelada", :mensaje)

    id = Util2.ingresar("ID de la necesidad: ", :texto)
    nuevo_estado = Util2.ingresar("Nuevo estado: ", :texto)

    case Necesidades.cambiar_estado(
           id,
           nuevo_estado,
           Map.get(estado, :necesidades, [])
         ) do
      {:ok, necesidad, lista_actualizada} ->
        Util2.mostrar(
          "El estado de #{necesidad.id} se actualizó a #{necesidad.estado}.",
          :mensaje
        )

        guardar_cambio_necesidades(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible cambiar el estado: #{razon}", :error)
        estado
    end
  end

  defp ordenar_necesidades(estado) do
    necesidades =
      estado
      |> Map.get(:necesidades, [])
      |> Necesidades.ordenar_por_prioridad()

    Util2.mostrar(
      "\n========== NECESIDADES ORDENADAS POR PRIORIDAD ==========",
      :mensaje
    )

    Util2.mostrar(
      coleccion_texto(:necesidades, necesidades),
      :mensaje
    )
  end

  # Actualiza el estado general y guarda la colección en el archivo.
  defp guardar_cambio_necesidades(estado, lista_actualizada) do
    case Gestor.actualizar(estado, :necesidades, lista_actualizada) do
      {:ok, nuevo_estado} ->
        Util2.mostrar("Los cambios fueron guardados correctamente.", :mensaje)
        nuevo_estado

      {:error, razon} ->
        Util2.mostrar("Error al guardar los cambios: #{razon}", :error)
        estado
    end
  end

  # SUBMENÚ DE RECURSOS

  defp gestionar_recursos(estado) do
    Util2.mostrar("\n========== GESTIÓN DE RECURSOS ==========", :mensaje)
    Util2.mostrar("1. Consultar inventario", :mensaje)
    Util2.mostrar("2. Registrar recurso", :mensaje)
    Util2.mostrar("3. Registrar entrada", :mensaje)
    Util2.mostrar("4. Registrar salida", :mensaje)
    Util2.mostrar("5. Transferir recurso", :mensaje)
    Util2.mostrar("6. Consultar historial de movimientos", :mensaje)
    Util2.mostrar("7. Volver al menú principal", :mensaje)

    opcion = Util2.ingresar("Seleccione una opción: ", :entero)

    case opcion do
      1 ->
        mostrar_inventario(estado)
        gestionar_recursos(estado)

      2 ->
        nuevo_estado = registrar_recurso(estado)
        gestionar_recursos(nuevo_estado)

      3 ->
        nuevo_estado = registrar_movimiento(estado, :entrada)
        gestionar_recursos(nuevo_estado)

      4 ->
        nuevo_estado = registrar_movimiento(estado, :salida)
        gestionar_recursos(nuevo_estado)

      5 ->
        nuevo_estado = transferir_recurso(estado)
        gestionar_recursos(nuevo_estado)

      6 ->
        mostrar_historial_recursos(estado)
        gestionar_recursos(estado)

      7 ->
        Util2.mostrar("Regresando al menú principal.", :mensaje)
        estado

      _ ->
        Util2.mostrar("Opción no válida.", :error)
        gestionar_recursos(estado)
    end
  end

  defp mostrar_inventario(estado) do
    recursos = Map.get(estado, :recursos, [])

    Util2.mostrar(
      coleccion_texto(:recursos, recursos),
      :mensaje
    )
  end

  defp registrar_recurso(estado) do
    Util2.mostrar("\n========== REGISTRAR RECURSO ==========", :mensaje)

    codigo = Util2.ingresar("Código: ", :texto)
    nombre = Util2.ingresar("Nombre: ", :texto)
    categoria = Util2.ingresar("Categoría: ", :texto)
    cantidad = Util2.ingresar("Cantidad inicial: ", :entero)
    unidad = Util2.ingresar("Unidad de medida: ", :texto)
    ubicacion = Util2.ingresar("Ubicación: ", :texto)

    datos = %{
      codigo: codigo,
      nombre: nombre,
      categoria: categoria,
      cantidad: cantidad,
      unidad: unidad,
      ubicacion: ubicacion
    }

    case Recursos.registrar(datos, Map.get(estado, :recursos, [])) do
      {:ok, recurso, lista_actualizada} ->
        Util2.mostrar(
          "Recurso #{recurso.nombre} registrado correctamente.",
          :mensaje
        )

        guardar_cambio_recursos(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible registrar: #{razon}", :error)
        estado
    end
  end

  defp registrar_movimiento(estado, tipo) do
    codigo = Util2.ingresar("Código del recurso: ", :texto)
    cantidad = Util2.ingresar("Cantidad: ", :entero)
    recursos = Map.get(estado, :recursos, [])

    resultado =
      case tipo do
        :entrada -> Recursos.entrada(codigo, cantidad, recursos)
        :salida -> Recursos.salida(codigo, cantidad, recursos)
      end

    case resultado do
      {:ok, recurso, lista_actualizada} ->
        Util2.mostrar(
          "Operación realizada. Existencias actuales: #{recurso.cantidad} #{recurso.unidad}.",
          :mensaje
        )

        guardar_cambio_recursos(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible realizar el movimiento: #{razon}", :error)
        estado
    end
  end

  defp transferir_recurso(estado) do
    Util2.mostrar("\n========== TRANSFERIR RECURSO ==========", :mensaje)

    codigo = Util2.ingresar("Código del recurso: ", :texto)
    cantidad = Util2.ingresar("Cantidad a transferir: ", :entero)
    destino = Util2.ingresar("Ubicación de destino: ", :texto)

    case Recursos.transferir(
           codigo,
           cantidad,
           destino,
           Map.get(estado, :recursos, [])
         ) do
      {:ok, recurso, lista_actualizada} ->
        Util2.mostrar(
          "Transferencia registrada. Existencias restantes: #{recurso.cantidad}.",
          :mensaje
        )

        guardar_cambio_recursos(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible transferir: #{razon}", :error)
        estado
    end
  end

  defp mostrar_historial_recursos(estado) do
    codigo = Util2.ingresar("Código del recurso: ", :texto)

    case Recursos.buscar(codigo, Map.get(estado, :recursos, [])) do
      {:ok, recurso} ->
        Util2.mostrar(
          coleccion_texto(:historial_de_movimientos, recurso.historial),
          :mensaje
        )

      {:error, razon} ->
        Util2.mostrar(razon, :error)
    end
  end

  defp guardar_cambio_recursos(estado, lista_actualizada) do
    case Gestor.actualizar(estado, :recursos, lista_actualizada) do
      {:ok, nuevo_estado} ->
        Util2.mostrar("Los cambios fueron guardados correctamente.", :mensaje)
        nuevo_estado

      {:error, razon} ->
        Util2.mostrar("Error al guardar los cambios: #{razon}", :error)
        estado
    end
  end

  # ==========================================
  # SUBMENU DE PERSONAS AFECTADAS
  # ==========================================

  defp gestionar_personas(estado) do
    Util2.mostrar("\n========== PERSONAS AFECTADAS ==========", :mensaje)
    Util2.mostrar("1. Consultar personas", :mensaje)
    Util2.mostrar("2. Registrar persona afectada", :mensaje)
    Util2.mostrar("3. Buscar persona por documento", :mensaje)
    Util2.mostrar("4. Actualizar estado de una persona", :mensaje)
    Util2.mostrar("5. Filtrar personas por zona", :mensaje)
    Util2.mostrar("6. Volver al menu principal", :mensaje)

    opcion = Util2.ingresar("Seleccione una opcion: ", :entero)

    case opcion do
      1 ->
        Util2.mostrar(
          coleccion_texto(:personas, Personas.listar(Map.get(estado, :personas, []))),
          :mensaje
        )

        gestionar_personas(estado)

      2 ->
        nuevo_estado = registrar_persona(estado)
        gestionar_personas(nuevo_estado)

      3 ->
        documento = Util2.ingresar("Documento de la persona: ", :texto)

        case Personas.buscar_por_documento(documento, Map.get(estado, :personas, [])) do
          {:ok, persona} ->
            Util2.mostrar(inspect(persona, pretty: true), :mensaje)

          {:error, razon} ->
            Util2.mostrar(razon, :error)
        end

        gestionar_personas(estado)

      4 ->
        nuevo_estado = actualizar_estado_persona(estado)
        gestionar_personas(nuevo_estado)

      5 ->
        zona = Util2.ingresar("Nombre de la zona: ", :texto)

        personas =
          Personas.filtrar_por_zona(zona, Map.get(estado, :personas, []))

        Util2.mostrar(coleccion_texto(:personas_filtradas, personas), :mensaje)
        gestionar_personas(estado)

      6 ->
        estado

      _ ->
        Util2.mostrar("Opcion no valida.", :error)
        gestionar_personas(estado)
    end
  end

  defp registrar_persona(estado) do
    Util2.mostrar("\n========== REGISTRAR PERSONA ==========", :mensaje)

    id = Util2.ingresar("ID de la persona: ", :texto)
    nombre = Util2.ingresar("Nombre completo: ", :texto)
    documento = Util2.ingresar("Documento: ", :texto)
    edad = Util2.ingresar("Edad: ", :entero)
    zona = Util2.ingresar("Zona donde fue reportada: ", :texto)

    estado_persona =
      Util2.ingresar(
        "Estado (desaparecida, localizada, hospitalizada, fallecida, sin_confirmar): ",
        :texto
      )

    datos = %{
      id: id,
      nombre: nombre,
      documento: documento,
      edad: edad,
      zona: zona,
      estado: estado_persona
    }

    case Personas.registrar(datos, Map.get(estado, :personas, [])) do
      {:ok, persona, lista_actualizada} ->
        Util2.mostrar("Persona #{persona.nombre} registrada correctamente.", :mensaje)
        guardar_cambio_personas(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible registrar la persona: #{razon}", :error)
        estado
    end
  end

  defp actualizar_estado_persona(estado) do
    Util2.mostrar("\n========== ACTUALIZAR ESTADO DE PERSONA ==========", :mensaje)

    id = Util2.ingresar("ID de la persona: ", :texto)

    nuevo_estado =
      Util2.ingresar(
        "Nuevo estado (desaparecida, localizada, hospitalizada, fallecida, sin_confirmar): ",
        :texto
      )

    case Personas.actualizar_estado(
           id,
           nuevo_estado,
           Map.get(estado, :personas, [])
         ) do
      {:ok, persona, lista_actualizada} ->
        Util2.mostrar("Estado actualizado a #{persona.estado}.", :mensaje)
        guardar_cambio_personas(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible actualizar: #{razon}", :error)
        estado
    end
  end

  defp guardar_cambio_personas(estado, lista_actualizada) do
    case Gestor.actualizar(estado, :personas, lista_actualizada) do
      {:ok, nuevo_estado} ->
        Util2.mostrar("Los cambios de personas fueron guardados correctamente.", :mensaje)
        nuevo_estado

      {:error, razon} ->
        Util2.mostrar("Error al guardar: #{razon}", :error)
        estado
    end
  end

  # ==========================================
  # SUBMENU DE COMUNICACION FAMILIAR
  # ==========================================

  defp gestionar_mensajes(estado) do
    Util2.mostrar("\n========== COMUNICACION FAMILIAR ==========", :mensaje)
    Util2.mostrar("1. Enviar mensaje", :mensaje)
    Util2.mostrar("2. Consultar todos los mensajes", :mensaje)
    Util2.mostrar("3. Consultar mensajes recibidos", :mensaje)
    Util2.mostrar("4. Consultar historial de un usuario", :mensaje)
    Util2.mostrar("5. Actualizar estado de un mensaje", :mensaje)
    Util2.mostrar("6. Volver al menu principal", :mensaje)

    opcion = Util2.ingresar("Seleccione una opcion: ", :entero)

    case opcion do
      1 ->
        nuevo_estado = enviar_mensaje(estado)
        gestionar_mensajes(nuevo_estado)

      2 ->
        Util2.mostrar(
          coleccion_texto(:mensajes, Mensajes.listar(Map.get(estado, :mensajes, []))),
          :mensaje
        )

        gestionar_mensajes(estado)

      3 ->
        usuario = Util2.ingresar("ID del destinatario: ", :texto)

        recibidos =
          Mensajes.recibidos(usuario, Map.get(estado, :mensajes, []))

        Util2.mostrar(coleccion_texto(:mensajes_recibidos, recibidos), :mensaje)
        gestionar_mensajes(estado)

      4 ->
        usuario = Util2.ingresar("ID del usuario: ", :texto)

        historial =
          Mensajes.historial_usuario(usuario, Map.get(estado, :mensajes, []))

        Util2.mostrar(coleccion_texto(:historial_mensajes, historial), :mensaje)
        gestionar_mensajes(estado)

      5 ->
        nuevo_estado = actualizar_estado_mensaje(estado)
        gestionar_mensajes(nuevo_estado)

      6 ->
        estado

      _ ->
        Util2.mostrar("Opcion no valida.", :error)
        gestionar_mensajes(estado)
    end
  end

  defp enviar_mensaje(estado) do
    Util2.mostrar("\n========== ENVIAR MENSAJE ==========", :mensaje)

    id = Util2.ingresar("ID del mensaje: ", :texto)
    remitente = Util2.ingresar("ID del remitente: ", :texto)
    destinatario = Util2.ingresar("ID del destinatario: ", :texto)
    contenido = Util2.ingresar("Contenido del mensaje: ", :texto)

    datos = %{
      id: id,
      remitente: remitente,
      destinatario: destinatario,
      contenido: contenido
    }

    case Mensajes.enviar(datos, Map.get(estado, :mensajes, [])) do
      {:ok, mensaje, lista_actualizada} ->
        Util2.mostrar("Mensaje #{mensaje.id} enviado correctamente.", :mensaje)
        guardar_cambio_mensajes(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible enviar el mensaje: #{razon}", :error)
        estado
    end
  end

  defp actualizar_estado_mensaje(estado) do
    Util2.mostrar("\n========== ACTUALIZAR ESTADO DEL MENSAJE ==========", :mensaje)

    id = Util2.ingresar("ID del mensaje: ", :texto)

    nuevo_estado =
      Util2.ingresar(
        "Nuevo estado (entregado, leido, fallido): ",
        :texto
      )

    case Mensajes.actualizar_estado(
           id,
           nuevo_estado,
           Map.get(estado, :mensajes, [])
         ) do
      {:ok, mensaje, lista_actualizada} ->
        Util2.mostrar("Estado del mensaje actualizado a #{mensaje.estado}.", :mensaje)
        guardar_cambio_mensajes(estado, lista_actualizada)

      {:error, razon} ->
        Util2.mostrar("No fue posible actualizar: #{razon}", :error)
        estado
    end
  end

  defp guardar_cambio_mensajes(estado, lista_actualizada) do
    case Gestor.actualizar(estado, :mensajes, lista_actualizada) do
      {:ok, nuevo_estado} ->
        Util2.mostrar("Los cambios de mensajes fueron guardados correctamente.", :mensaje)
        nuevo_estado

      {:error, razon} ->
        Util2.mostrar("Error al guardar: #{razon}", :error)
        estado
    end
  end

  # ==========================================
  # GESTION DE MASCOTAS
  # ==========================================

  defp gestionar_mascotas(estado) do
    Util2.mostrar("\n========== MASCOTAS ==========", :mensaje)
    Util2.mostrar("1. Consultar reportes", :mensaje)
    Util2.mostrar("2. Registrar mascota perdida o encontrada", :mensaje)
    Util2.mostrar("3. Buscar posibles coincidencias", :mensaje)
    Util2.mostrar("4. Confirmar coincidencia", :mensaje)
    Util2.mostrar("5. Volver", :mensaje)

    case Util2.ingresar("Seleccione una opcion: ", :entero) do
      1 ->
        Util2.mostrar(
          coleccion_texto(:mascotas, Mascotas.listar(Map.get(estado, :mascotas, []))),
          :mensaje
        )

        gestionar_mascotas(estado)

      2 ->
        nuevo = registrar_mascota(estado)
        gestionar_mascotas(nuevo)

      3 ->
        id = Util2.ingresar("ID del reporte: ", :texto)

        case Mascotas.posibles_coincidencias(id, Map.get(estado, :mascotas, [])) do
          {:ok, coincidencias} ->
            Util2.mostrar(inspect(coincidencias, pretty: true), :mensaje)

          {:error, razon} ->
            Util2.mostrar(razon, :error)
        end

        gestionar_mascotas(estado)

      4 ->
        nuevo = confirmar_mascota(estado)
        gestionar_mascotas(nuevo)

      5 ->
        estado

      _ ->
        Util2.mostrar("Opcion no valida.", :error)
        gestionar_mascotas(estado)
    end
  end

  defp registrar_mascota(estado) do
    Util2.mostrar("\n========== REGISTRAR MASCOTA ==========", :mensaje)

    datos = %{
      id: Util2.ingresar("ID del reporte: ", :texto),
      tipo: Util2.ingresar("Tipo (perdida/encontrada): ", :texto),
      especie: Util2.ingresar("Especie: ", :texto),
      nombre: Util2.ingresar("Nombre de la mascota (si se conoce): ", :texto),
      color: Util2.ingresar("Color: ", :texto),
      tamano: Util2.ingresar("Tamano: ", :texto),
      zona: Util2.ingresar("Zona: ", :texto),
      caracteristicas: Util2.ingresar("Caracteristicas: ", :texto),
      contacto: Util2.ingresar("Contacto del responsable: ", :texto)
    }

    case Mascotas.registrar(datos, Map.get(estado, :mascotas, [])) do
      {:ok, mascota, lista} ->
        Util2.mostrar("Reporte #{mascota.id} registrado correctamente.", :mensaje)
        guardar_cambio_mascotas(estado, lista)

      {:error, razon} ->
        Util2.mostrar(razon, :error)
        estado
    end
  end

  defp confirmar_mascota(estado) do
    id1 = Util2.ingresar("ID del primer reporte: ", :texto)
    id2 = Util2.ingresar("ID del segundo reporte: ", :texto)

    case Mascotas.confirmar_coincidencia(
           id1,
           id2,
           Map.get(estado, :mascotas, [])
         ) do
      {:ok, lista} ->
        Util2.mostrar("Coincidencia confirmada. Ambos reportes fueron resueltos.", :mensaje)
        guardar_cambio_mascotas(estado, lista)

      {:error, razon} ->
        Util2.mostrar(razon, :error)
        estado
    end
  end

  defp guardar_cambio_mascotas(estado, lista) do
    case Gestor.actualizar(estado, :mascotas, lista) do
      {:ok, nuevo} ->
        nuevo

      {:error, razon} ->
        Util2.mostrar(razon, :error)
        estado
    end
  end

  # ==========================================
  # GESTION DE ALBERGUES
  # ==========================================

  defp gestionar_albergues(estado) do
    Util2.mostrar("\n========== ALBERGUES ==========", :mensaje)
    Util2.mostrar("1. Consultar albergues", :mensaje)
    Util2.mostrar("2. Registrar albergue", :mensaje)
    Util2.mostrar("3. Ingresar personas", :mensaje)
    Util2.mostrar("4. Retirar personas", :mensaje)
    Util2.mostrar("5. Consultar mayor ocupacion", :mensaje)
    Util2.mostrar("6. Volver", :mensaje)

    case Util2.ingresar("Seleccione una opcion: ", :entero) do
      1 ->
        Util2.mostrar(
          coleccion_texto(:albergues, Albergues.listar(Map.get(estado, :albergues, []))),
          :mensaje
        )

        gestionar_albergues(estado)

      2 ->
        nuevo = registrar_albergue(estado)
        gestionar_albergues(nuevo)

      3 ->
        nuevo = movimiento_albergue(estado, :ingresar)
        gestionar_albergues(nuevo)

      4 ->
        nuevo = movimiento_albergue(estado, :retirar)
        gestionar_albergues(nuevo)

      5 ->
        case Albergues.mayor_ocupacion(Map.get(estado, :albergues, [])) do
          {:ok, albergue} ->
            porcentaje = Albergues.porcentaje_ocupacion(albergue)

            Util2.mostrar(
              "Mayor ocupacion: #{albergue.nombre} - #{Float.round(porcentaje, 2)}%",
              :mensaje
            )

          {:error, razon} ->
            Util2.mostrar(razon, :error)
        end

        gestionar_albergues(estado)

      6 ->
        estado

      _ ->
        Util2.mostrar("Opcion no valida.", :error)
        gestionar_albergues(estado)
    end
  end

  defp registrar_albergue(estado) do
    datos = %{
      id: Util2.ingresar("ID del albergue: ", :texto),
      nombre: Util2.ingresar("Nombre: ", :texto),
      zona: Util2.ingresar("Zona: ", :texto),
      capacidad: Util2.ingresar("Capacidad maxima: ", :entero)
    }

    case Albergues.registrar(datos, Map.get(estado, :albergues, [])) do
      {:ok, albergue, lista} ->
        Util2.mostrar("Albergue #{albergue.nombre} registrado correctamente.", :mensaje)
        guardar_cambio_albergues(estado, lista)

      {:error, razon} ->
        Util2.mostrar(razon, :error)
        estado
    end
  end

  defp movimiento_albergue(estado, operacion) do
    id = Util2.ingresar("ID del albergue: ", :texto)
    cantidad = Util2.ingresar("Cantidad de personas: ", :entero)
    albergues = Map.get(estado, :albergues, [])

    resultado =
      case operacion do
        :ingresar -> Albergues.ingresar_personas(id, cantidad, albergues)
        :retirar -> Albergues.retirar_personas(id, cantidad, albergues)
      end

    case resultado do
      {:ok, albergue, lista} ->
        Util2.mostrar(
          "Operacion correcta. Ocupacion: #{albergue.ocupacion}/#{albergue.capacidad}",
          :mensaje
        )

        guardar_cambio_albergues(estado, lista)

      {:error, razon} ->
        Util2.mostrar(razon, :error)
        estado
    end
  end

  defp guardar_cambio_albergues(estado, lista) do
    case Gestor.actualizar(estado, :albergues, lista) do
      {:ok, nuevo} ->
        nuevo

      {:error, razon} ->
        Util2.mostrar(razon, :error)
        estado
    end
  end

  defp guardar_informacion(estado) do
    case Gestor.guardar(estado) do
      {:ok, mensaje} ->
        Util2.mostrar(mensaje, :mensaje)

      {:error, razon} ->
        Util2.mostrar("Error al guardar: #{razon}", :error)
    end
  end

  @doc "Convierte el resumen de las colecciones en texto."
  def resumen_texto(resumen) do
    resumen
    |> Enum.sort_by(fn {nombre, _cantidad} -> nombre end)
    |> Enum.map_join("\n", fn {nombre, cantidad} ->
      "#{nombre}: #{cantidad} registro(s)"
    end)
  end

  @doc "Convierte una colección de registros en texto."
  def coleccion_texto(nombre, registros) do
    encabezado = "========== #{nombre} =========="

    contenido =
      case registros do
        [] ->
          "No hay registros almacenados."

        elementos ->
          elementos
          |> Enum.with_index(1)
          |> Enum.map_join("\n", fn {elemento, indice} ->
            "#{indice}. #{inspect(elemento, pretty: true)}"
          end)
      end

    "#{encabezado}\n#{contenido}"
  end
end
